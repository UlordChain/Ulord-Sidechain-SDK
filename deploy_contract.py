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

import dconfig

USER_DATA_DIR = dconfig.USER_DATA_DIR
CURR_DIR = dconfig.CURR_DIR


class Deploy(object):
    def __init__(
            self,
            config=None,
            spath="",
            privateKey=None,
            keystorefile=None,
            keystore_pwd=None,
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
        provider = dconfig.provider

        self.gas_limit = limit if limit else dconfig.GAS_LIMIT
        self.gas_price = price if price else Web3.toWei("25", "gwei")
        self.w3 = Web3(HTTPProvider(dconfig.provider))
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
        self.addresses["self"] = self.account.address
        self.prepare_dir()  # 创建abi保存地址

    def prepare_dir(self):
        # 本地
        if not os.path.isdir(CURR_DIR):
            os.makedirs(CURR_DIR)
        abi_dir = os.path.join(CURR_DIR, "abi")
        if not os.path.isdir(abi_dir):
            os.mkdir(abi_dir)
        bin_dir = os.path.join(CURR_DIR, "bin")
        if not os.path.isdir(bin_dir):
            os.mkdir(bin_dir)

        # 全局
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

    def _build_transaction(self, func, gas_limit=None, gas_price=None, nonce=None):
        """将合约方法的调用构建为离线交易对象"""
        return func.buildTransaction({"nonce": nonce if nonce else self._nonce(),
                                      "gas": gas_limit if gas_limit else self.gas_limit,
                                      "gasPrice": gas_price if gas_price else self.gas_price, })

    def _sign_and_send_rawtransaction(self, transaction):
        signed = self.account.signTransaction(transaction)
        tx_hash = Web3.toHex(self.w3.eth.sendRawTransaction(signed.rawTransaction))
        return tx_hash

    def deploy(self, **kwargs):
        """ 编译和部署合约 """
        deploy_conf = self.conf["deploy"]
        # 加载账户
        accounts = deploy_conf['account_address']
        for name in accounts:
            account = accounts[name]
            if account == "self":
                account = self.account.address
            self.addresses[name] = Web3.toChecksumAddress(account)

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
                raise ValueError("No {} compilation results can be found".format(ck))
            abi_file = os.path.join(self.abi_dir, cname + ".abi")
            bin_file = os.path.join(self.bin_dir, cname + ".bin")
            abi_content = cv.get("abi")
            bin_content = cv.get("bin")
            self.save_file(abi_file, abi_content)
            self.save_file(bin_file, bin_content)
            factory = self.w3.eth.contract(abi=abi_content, bytecode=bin_content)
            arg = deploy_conf.get(cname)
            if Web3.isAddress(arg):
                deplpyed_contract_address = Web3.toChecksumAddress(arg)
                self.addresses[cname] = deplpyed_contract_address
                print("<{} | {}>  has been deployed, continue.".format(cname, deplpyed_contract_address))
                continue
            contract_address_args, constructor_args = arg
            args = []
            for name in contract_address_args:
                ca = self.addresses.get(name, None)
                if not ca:
                    raise ValueError("Cannot find {} contract address".format(name))
                args.append(ca)
            constructor_args = [Web3.toChecksumAddress(c) if Web3.isAddress(c) else c for c in constructor_args]
            args.extend(constructor_args)
            print("{} args: {}".format(cname, args))
            print("nonce: {}".format(self._nonce()))
            func = factory.constructor(*args)
            tx = self._build_transaction(func, **kwargs)
            tx_hash = self._sign_and_send_rawtransaction(transaction=tx)
            print("Waiting for [{} | {}] contract receipt...".format(cname, tx_hash))
            receipt = self.w3.eth.waitForTransactionReceipt(tx_hash, timeout=600)
            contractAddress = receipt["contractAddress"]
            self.addresses[cname] = contractAddress
            print("{} >>> txHash: {} | contractAddress: {}\n".format(cname, tx_hash, contractAddress))
            time.sleep(0.5)  # 预防获取nonce(交易数)时,请求太快而不准确
        self.save_file(os.path.join(USER_DATA_DIR, "contractAddresses.json"), self.addresses)
        print("All contracts are deployed.")
        self.activate()

    def save_file(self, file, data):
        with open(file, "w") as f:
            json.dump(data, f)
        if USER_DATA_DIR in file:
            file = file.replace(USER_DATA_DIR, CURR_DIR)
            with open(file, "w") as f:
                json.dump(data, f)

    def activate(self, **kwargs):
        """ 激活(添加白名单) """
        print("\nContracts are being activate(add white list)...\n")
        activate_conf = self.conf["activate"]
        for cname, func_list in activate_conf.items():
            contract_address = self.addresses[cname]
            with open(os.path.join(self.abi_dir, cname + ".abi")) as f:
                abi = json.load(f)
            contract = self.w3.eth.contract(address=contract_address, abi=abi)
            print("activate {} contracting".format(cname))
            for func_name, param_s in func_list.items():
                # for one function
                print("call {} , will do {} call ".format(func_name, len(param_s)))
                for param_o in param_s:
                    func = contract.functions.__getattribute__(func_name)
                    # add param
                    param_list = []
                    for param in param_o:
                        p = self.addresses.get(param)
                        if p is None:
                            p = param
                        param_list.append(p)
                    func = func(*param_list)
                    tx = self._build_transaction(func, **kwargs)
                    tx_hash = self._sign_and_send_rawtransaction(transaction=tx)
                    print("input : {}".format(param_o))
                    print("input change to : {}".format(param_list))
                    print("Waiting for  <{} | {}>  contract receipt...".format(cname, tx_hash))
                    receipt = self.w3.eth.waitForTransactionReceipt(tx_hash)
                    print("call {} successful. \nreceipt : {}\n".format(func_name, receipt))

        print("All white list are activated.")


if __name__ == "__main__":
    d = Deploy(
        config="deploy_contract.json",
        spath="sols",
        privateKey="93072BA0A53E6DA43526B5728B7D029A5ABE7F0E806A8D7A50CEB43423DF1052",
    )
    d.deploy()
