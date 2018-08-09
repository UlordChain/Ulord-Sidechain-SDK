# -*- coding: utf-8 -*-
# Copyright (c) 2016-2018 The Ulord Core Developers
#
# @Date    : 2018/8/2
# @Author  : Shu [Ulord DevTeam]
# @Email   : httpservlet@yeah.net
# @Des     :


import os
import json
import time
from web3 import Web3, HTTPProvider
from web3.eth import Account
from solc import compile_files
from web3.middleware import geth_poa_middleware
from appdirs import AppDirs

USER_DATA_DIR = AppDirs("UlordPySdk", "").user_data_dir


class Deploy(object):
    def __init__(
            self,
            config=None,
            spath="",
            privateKey=None,
            keystorefile=None,
            keystore_pwd=None,
            provider=None,
            limit=None,
            price=None,
    ):
        """
        :param config: 配置文件路径
        :param spath: 合约源文件目录
        :param privateKey: 部署合约者的私钥
        :param keystorefile: 部署合约者钱包文件
        :param keystore_pwd: 部署合约者钱包密码
        :param provider: 提供者(指定连接到哪个网络中)
        :param limit: 区块gas上限
        :param price: 区块gas价格
        """
        self.gas_limit = limit if limit else 6700000
        self.gas_price = price if price else Web3.toWei("25", "gwei")
        self.w3 = Web3(HTTPProvider(provider))
        # Rinkeby测试网络使用的是POA权威证明, 需要使用这个中间件才能正常工作
        # http://web3py.readthedocs.io/en/stable/middleware.html#geth-style-proof-of-authority
        if provider.startswith("https://rinkeby"):
            self.w3.middleware_stack.inject(geth_poa_middleware, layer=0)

        if privateKey:
            self.account = Account.privateKeyToAccount(privateKey)
        elif keystorefile and keystore_pwd:
            with open(keystorefile) as wf:
                wallet = json.load(wf)
                privateKey = Account.decrypt(wallet, keystore_pwd)
                self.account = Account.privateKeyToAccount(privateKey)
        else:
            raise ValueError(
                "The deployment contract requires a valid address."
            )
        config = config if config else "deploy_contract.json"
        self.conf = self._load_config(config)
        self.spath = spath
        self.addresses = {}  # 记录发布合约的合约地址

        if not os.path.isdir(USER_DATA_DIR):
            os.makedirs(USER_DATA_DIR)
        self.abi_dir = os.path.join(USER_DATA_DIR, "abi")
        if not os.path.isdir(self.abi_dir):
            os.mkdir(self.abi_dir)
        self.bin_dir = os.path.join(USER_DATA_DIR, "bin")
        if not os.path.isdir(self.bin_dir):
            os.mkdir(self.bin_dir)

    def _load_config(self, config):
        """ 加载配置文件内容

        :param config: 配置文件路径
        """
        with open(config) as f:
            conf = json.load(f)
        return conf

    def _nonce(self, value=0):
        nonce = self.w3.eth.getTransactionCount(self.account.address) + value
        return nonce

    def _build_transaction(
            self, func, gas_limit=None, gas_price=None, nonce=None
    ):
        """将合约方法的调用构建为离线交易对象"""
        return func.buildTransaction(
            {
                "nonce": nonce if nonce else self._nonce(),
                "gas": gas_limit if gas_limit else self.gas_limit,
                "gasPrice": gas_price if gas_price else self.gas_price,
            }
        )

    def _sign_and_send_rawtransaction(self, transaction):
        signed = self.account.signTransaction(transaction)
        tx_hash = Web3.toHex(
            self.w3.eth.sendRawTransaction(signed.rawTransaction)
        )
        return tx_hash

    def deploy(self, **kwargs):
        """ 编译和部署合约 """
        deploy_conf = self.conf["deploy"]
        sortkeys = deploy_conf["sortkeys"]
        if not isinstance(sortkeys, list):
            raise ValueError('"sortkeys" value error. ')
        sortfiles = [os.path.join(self.spath, key + ".sol") for key in sortkeys]
        compileds = compile_files(sortfiles)
        print("Smart contracts are being deployed...\n")
        for cname in sortkeys:
            cv = None
            for ck in compileds.keys():
                if ck.endswith(cname):
                    cv = compileds[ck]
                    break
            if not cv:
                raise ValueError(
                    "No {} compilation results can be found".format(ck)
                )
            abi_file = os.path.join(self.abi_dir, cname + ".abi")
            bin_file = os.path.join(self.bin_dir, cname + ".bin")
            abi_content = cv.get("abi")
            bin_content = cv.get("bin")
            with open(abi_file, "w") as f:
                json.dump(abi_content, f)
            with open(bin_file, "w") as f:
                json.dump(bin_content, f)

            factory = self.w3.eth.contract(
                abi=abi_content, bytecode=bin_content
            )
            arg = deploy_conf.get(cname)
            if Web3.isAddress(arg):
                deplpyed_contract_address = Web3.toChecksumAddress(arg)
                self.addresses[cname] = deplpyed_contract_address
                print(
                    "<{} | {}>  has been deployed, continue.".format(
                        cname, deplpyed_contract_address
                    )
                )
                continue
            contract_address_args, constructor_args = arg
            args = []
            for name in contract_address_args:
                ca = self.addresses.get(name, None)
                if not ca:
                    raise ValueError(
                        "Cannot find {} contract address".format(name)
                    )
                args.append(ca)
            constructor_args = [
                Web3.toChecksumAddress(c) if Web3.isAddress(c) else c
                for c in constructor_args
            ]
            args.extend(constructor_args)
            print("args: {}".format(args))
            print("nonce: {}".format(self._nonce()))
            func = factory.constructor(*args)
            tx = self._build_transaction(func, **kwargs)
            tx_hash = self._sign_and_send_rawtransaction(transaction=tx)
            print(
                "Waiting for [{} | {}] contract receipt...".format(
                    cname, tx_hash
                )
            )
            receipt = self.w3.eth.waitForTransactionReceipt(tx_hash)
            contractAddress = receipt["contractAddress"]
            self.addresses[cname] = contractAddress
            print(
                "{} >>> txHash: {} | contractAddress: {}\n".format(
                    cname, tx_hash, contractAddress
                )
            )
            time.sleep(0.5)  # 预防获取nonce(交易数)时,请求太快而不准确
        with open(
                os.path.join(USER_DATA_DIR, "contractAddresses.json"), "w"
        ) as f:
            json.dump(self.addresses, f)
        print("All contracts are deployed.")

        # self.activate(**kwargs)

    def activate(self, **kwargs):
        """ 激活(添加白名单) """
        print("\nContracts are being activate(add white list)...\n")
        activate_conf = self.conf["activate"]
        for cname, white_address in activate_conf.items():
            contract_address = self.addresses[cname]
            with open(os.path.join(self.abi_dir, cname + ".abi")) as f:
                abi = json.load(f)
            contract = self.w3.eth.contract(address=contract_address, abi=abi)
            func = contract.functions.mulInsertWhite(
                [self.addresses[addr] for addr in white_address]
            )
            tx = self._build_transaction(func, **kwargs)
            tx_hash = self._sign_and_send_rawtransaction(transaction=tx)
            print(
                "Waiting for  <{} | {}>  contract receipt...".format(
                    cname, tx_hash
                )
            )
            receipt = self.w3.eth.waitForTransactionReceipt(tx_hash)
            log_hash = Web3.toHex(receipt.logs[0].topics[0])
            if (
                    log_hash == "0x0489f2369368f4688acd0121"
                                "07ac5a7d98ca739b913449d852f35d871e433cc3"
            ):
                print("Activation failed, please check the log.\n")
            else:
                print("Activation successful.\n")

        print("All white list are activated.")


if __name__ == "__main__":
    d = Deploy(
        config="deploy_contract.json",
        spath="sols",
        privateKey="93072BA0A53E6DA43526B5728B7D029A5ABE7F0E806A8D7A50CEB43423DF1052",
        provider="https://rinkeby.infura.io/v3/7226f0ad456a4f1189fee961011684ac",
    )
    d.deploy()
