# -*- coding: utf-8 -*-
# Copyright (c) 2016-2018 The Ulord Core Developers
#
# @Date    : 2018/7/11
# @Author  : Shu [Ulord DevTeam]
# @Email   : httpservlet@yeah.net
# @Des     :

import json
import os
from pprint import pprint
from web3.middleware import geth_poa_middleware
from web3 import Web3
from web3 import HTTPProvider
from web3.eth import Eth
import dconfig
from eth_account import Account
from functools import wraps

# ULORD_PROVIDER = dconfig.provider
# USH_TOKEN_ADDRESS = dconfig.USH_TOKEN_ADDRESS
# CENTER_PUBLISH_ADDRESS = dconfig.CENTER_PUBLISH_ADDRESS
# BLOCK_GAS_LIMIT = dconfig.BLOCK_GAS_LIMIT
GAS_PRICE = Web3.toWei('2', 'gwei')


def check_account(func):
    """检查在调用转账等操作前, 是否设置了account"""

    @wraps(func)
    def wrapper(*args, **kwargs):
        self = args[0]
        if not hasattr(self, "account") or not self.account:
            raise ValueError(
                "No account is set, use the set_account_* to set the account, "
                "or use the create() to new an account."
            )
        return func(*args, **kwargs)

    return wrapper


class ContentContract(object):
    """Content contract"""

    def __init__(self, keystore_file, keystore_pwd,
                 private_key=None,
                 provider=dconfig.provider,
                 gas_price=GAS_PRICE, ):
        """ 合约方法调用类
        参数有可能会变化, 所以调用时最好指定参数名
        :param keystore_file: user account keystore file, which include user account private key
        :param keystore_pwd: user account keystore password
        :param provider: Ulord side provider, such as http://xxxx:yyy, which is a RPC endpoint
        """
        self.web3 = Web3(HTTPProvider(provider))
        self.gas_limit = dconfig.BLOCK_GAS_LIMIT
        self.gas_price = gas_price

        self.last_tx = None

        if private_key:
            self.set_account_from_privatekey(private_key)
        elif keystore_file and keystore_pwd:
            self.set_account_from_wallet(keystore_file, keystore_pwd)

        # Rinkeby测试网络使用的是POA权威证明, 需要使用这个插件才能正常工作
        # http://web3py.readthedocs.io/en/stable/middleware.html#geth-style-proof-of-authority
        if provider.startswith("https://rinkeby"):
            self.web3.middleware_stack.inject(geth_poa_middleware, layer=0)
        self.eth = Eth(self.web3)

        # 装载所有合约
        self.reloading_contract()

    def _load_wallet(self, wallet_file):
        if not os.path.isfile(wallet_file):
            wallet_file = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'resources', 'keystore', wallet_file)
            if not os.path.isfile(wallet_file):
                raise ValueError("Wallet file not a valid path.")
        with open(wallet_file) as wf:
            wallet = json.load(wf)
        return wallet

    def _save_wallet(self, wallet, file_name):
        wf = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'resources', 'keystore',
                          "{}.json".format(file_name))
        print("Wallet file address:\n{}".format(wf))
        with open(wf, "w") as f:
            json.dump(wallet, f)

    def _valid_address(self, address):
        """验证是否是一个以太坊地址, 用EIP55校验和返回给定的地址。"""
        if not Web3.isAddress(address):
            raise ValueError('"{}" not a valid address.'.format(address))
        address = Web3.toChecksumAddress(address)
        return address

    def _load_abi(self):
        abi_path = os.path.join(dconfig.CURR_DIR, 'abi')
        file_list = os.listdir(abi_path)
        self.abi_files = {}
        for i in file_list:
            if not i.endswith(".abi"):
                continue
            with open(os.path.join(abi_path, i)) as cp:
                cp_abi = cp.read()
                self.abi_files[i[:-4]] = json.loads(cp_abi)

    def _nonce(self, value=0):
        nonce = self.eth.getTransactionCount(self.account.address) + value
        return nonce

    def _build_transaction(self, func, gas_limit=None, gas_price=None, nonce=None):
        """将合约方法的调用构建为离线交易对象"""
        return func.buildTransaction({"nonce": nonce if nonce else self._nonce(),
                                      "gas": gas_limit if gas_limit else self.gas_limit,
                                      "gasPrice": gas_price if gas_price else self.gas_price, })

    def _sign_and_send_rawtransaction(self, transaction):
        signed = self.account.signTransaction(transaction)
        tx_hash = Web3.toHex(self.eth.sendRawTransaction(signed.rawTransaction))
        return tx_hash

    def create(self, wallet_password):
        """创建一个账户, 保存keyfile到对应目录的json文件中, 且返回私钥和地址"""
        setattr(self, "account", Account.create())
        wallet = self.account.encrypt(wallet_password)
        self._save_wallet(wallet, self.account.address)
        return dict(
            privateKey=Web3.toHex(self.account.privateKey),
            address=self.account.address,
        )

    def set_account_from_privatekey(self, private_key, wallet_password=None):
        """如果有钱包密码, 则创建对应的keystore文件. 反之 ,则不新建"""
        setattr(self, "account", Account.privateKeyToAccount(private_key))
        if wallet_password:
            wallet = self.account.encrypt(wallet_password)
            self._save_wallet(wallet, self.account.address)
        self.main_address = self.web3.eth.account.privateKeyToAccount(private_key).address
        return dict(
            privateKey=Web3.toHex(self.account.privateKey),
            address=self.account.address,
        )

    def set_account_from_wallet(self, wallet_file, wallet_password):
        """从密钥文件加载accout对象"""
        wallet = self._load_wallet(wallet_file)
        private_key = Account.decrypt(wallet, wallet_password)
        setattr(self, "account", Account.privateKeyToAccount(private_key))
        self.main_address = self.web3.eth.account.privateKeyToAccount(private_key).address
        return dict(
            privateKey=Web3.toHex(private_key), address=self.account.address
        )

    def get_for_receipt(self, tx_hash):
        """ 获取交易回执
        :param tx_hash: 获取交易回执(只有已打包的交易才有数据,否则返回None)
        :return:
        """
        return self.web3.eth.getTransactionReceipt(tx_hash)

    def get_gas_balance(self, address):
        """ 获取侧链余额
        """
        if address is None:
            address = self.main_address
        address = self._valid_address(address)
        balance = self.web3.eth.getBalance(address, 'latest')
        return self.web3.fromWei(balance, 'ether')

    @check_account
    def transfer_gas(self, to_address, value):
        """ gas就是侧链的币,

        :param to_address: 接收地址
        :param value: 转账金额(wei)
        :return: 交易hash
        """
        print("nonce:", self._nonce())
        to_address = self._valid_address(to_address)
        payload = {
            "to": to_address,
            "value": value,
            "gas": self.gas_limit,
            "gasPrice": self.gas_price,
            "nonce": self._nonce(),
        }
        res = self._sign_and_send_rawtransaction(payload)
        self.last_tx = res
        return res

    def transfer_tokens(self, addresses, qualitys):
        """ 多地址结算
        :param addresses: List, 结算的地址列表
        :param qualitys: List, 结算地址列表对应的金额
        """
        for i, address in enumerate(addresses):
            addresses[i] = self._valid_address(address)
        for i, quality in enumerate(qualitys):
            qualitys[i] = int(quality)
        publish_tx = self.contract["MulTransfer"].functions.mulPayDiff(addresses, qualitys).buildTransaction({
            "nonce": self._nonce(), "gas": self.gas_limit, "gasPrice": self.gas_price})
        res = self._sign_and_send_rawtransaction(publish_tx)
        self.last_tx = res
        return res

    # zza write

    def reloading_contract(self):
        try:
            # 所有合约的abi
            self._load_abi()
            # 所有合约
            self._load_contract()
        except FileNotFoundError:
            print("Please use the deploy_contract command to deploy the contract first, or manually prepare the "
                  "contract address。")

    def _load_contract(self):
        # 读取合约地址
        with open(os.path.join(dconfig.CURR_DIR, "contractAddresses.json")) as wf:
            contract_addrs = json.load(wf)
        self.contract = {}
        # 装载合约
        for contract, addr in contract_addrs.items():
            try:
                self.contract[contract] = self.web3.eth.contract(address=addr, abi=self.abi_files[contract])
            except:
                continue
            view_funcs = []
            abi = {}
            for func in self.abi_files[contract]:
                if func['type'] == 'function':
                    if func.get('constant') and func.get("stateMutability") == 'view':
                        view_funcs.append(func["name"])
                    abi[func['name']] = func
            self.contract[contract].view_funcs = view_funcs
            self.contract[contract].abi = abi

    @check_account
    def func_call(self, contract_name, function, param):
        # 找到合约中对应的函数
        contract = self.contract[contract_name]
        try:
            func = contract.functions.__getattribute__(function)
        except AttributeError:
            return "{} there is no {} function".format(contract_name, function)
        # 准备参数
        inputs = contract.abi[function]['inputs']
        param = self.format_param(param, inputs)
        # 增加参数
        func = func() if len(param) == 0 else func(*param)
        # 静态函数
        if function in self.contract[contract_name].view_funcs:
            return func.call()
        # 需要上链的函数
        if self.last_tx is None or self.get_for_receipt(self.last_tx) is not None:
            tx = self._build_transaction(func)
            res = self._sign_and_send_rawtransaction(transaction=tx)
            self.last_tx = res
            print("Call successful , transaction hash:")
            return res
        else:
            print("The last transaction was not confirmed , please call get_for_receipt to view the last transaction")
            return self.last_tx

    def format_param(self, param, inputs):
        if isinstance(param, list):
            res = param
        else:
            res = list(param)
        if len(param) != len(inputs):
            return "Less parameters"
        for i in range(len(inputs)):
            _type = inputs[i].get('type')
            if _type.endswith("[]"):
                return "Array arguments are not recommended for command-line input, use http://remix.ethereum.org/ " \
                       "manually "
            elif _type in ['uint256', 'uint8']:
                res[i] = int(param[i])
            elif 'bool' == _type:
                res[i] = bool(param[i])
            elif 'address' == _type:
                res[i] = self._valid_address(param[i])
            else:
                continue
        return res

    def get_last_call_info(self):
        if self.last_tx is None:
            return None
        return self.get_for_receipt(self.last_tx)


if __name__ == '__main__':
    c = ContentContract('haibo.json', '12345678')
