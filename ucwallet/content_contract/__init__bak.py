# -*- coding: utf-8 -*-
# Copyright (c) 2016-2018 The Ulord Core Developers
#
# @Date    : 2018/7/11
# @Author  : Shu [Ulord DevTeam]
# @Email   : httpservlet@yeah.net
# @Des     :

import random
import json
import os
from web3 import Web3
from web3 import HTTPProvider

# ULORD_PROVIDER = "http://192.168.14.197:44444"
import dconfig

ULORD_PROVIDER = dconfig.provider
# ULORD_PROVIDER = "https://rinkeby.infura.io/v3/7226f0ad456a4f1189fee961011684ac",
USH_TOKEN_ADDRESS = dconfig.USH_TOKEN_ADDRESS
CENTER_PUBLISH_ADDRESS = dconfig.CENTER_PUBLISH_ADDRESS
BLOCK_GAS_LIMIT = dconfig.BLOCK_GAS_LIMIT
GAS_PRICE = Web3.toWei('2', 'gwei')


class ContentContract(object):
    """Content contract"""

    def __init__(self, keystorefile, keystore_pwd, ushtoken_addr=USH_TOKEN_ADDRESS,
                 centerpublish_addr=CENTER_PUBLISH_ADDRESS, ulord_provider=ULORD_PROVIDER,
                 block_gas_limit=BLOCK_GAS_LIMIT, gas_price=GAS_PRICE):
        """ 合约方法调用类

        note: 参数有可能会变化, 所以调用时最好指定参数名
        :param ushtoken_addr:  token address which has deploy to ulord side chain
        :param centerpublish_addr: a publish smart contract which has deply to ulord side chain
        :param ulord_provider: Ulord side provider, such as http://xxxx:yyy, which is a RPC endpoint
        :param keystorefile: user account keystore file, which include user account private key
        :param keystore_pwd: user account keystore password
        """
        self.web3 = Web3(HTTPProvider(ulord_provider))
        self.ushtoken_addr = self.web3.toChecksumAddress(ushtoken_addr)
        self.centerpublish_addr = self.web3.toChecksumAddress(centerpublish_addr)
        self.block_gas_limit = block_gas_limit
        self.gas_price = gas_price

        self._decrypt_private_key(keystorefile, keystore_pwd)
        self._load_abi()
        self.ushtoken_contract = self.web3.eth.contract(address=self.ushtoken_addr, abi=self.ushtoken_abi)
        self.centerpublish_contract = self.web3.eth.contract(address=self.centerpublish_addr,
                                                             abi=self.centerpublish_abi)

    def set_private_key(self, keystorefile, keystore_pwd):
        self._decrypt_private_key(keystorefile, keystore_pwd)

    def _decrypt_private_key(self, keystorefile, keystore_pwd):
        if not os.path.isfile(keystorefile):
            keystorefile = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'resources', 'keystore',
                                        keystorefile)
        with open(keystorefile) as keyfile:
            encrypted_key = keyfile.read()
            # tip: do not save the key or password anywhere, especially into a shared source file
            self._private_key = self.web3.eth.account.decrypt(encrypted_key, keystore_pwd)
            self.main_address = self.web3.eth.account.privateKeyToAccount(self._private_key).address

    def _load_abi(self):
        abi_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'resources', 'abi')
        with open(os.path.join(abi_path, "USHToken.abi")) as ush:
            ush_abi = ush.read()
            self.ushtoken_abi = json.loads(ush_abi)
        with open(os.path.join(abi_path, "CenterPublish.abi")) as cp:
            cp_abi = cp.read()
            self.centerpublish_abi = json.loads(cp_abi)

    def _valid_address(self, address):
        if not self.web3.isAddress(address):
            raise ValueError('"{}" not a valid address.'.format(address))
        address = self.web3.toChecksumAddress(address)
        return address

    def _nonce(self, value=0):
        nonce = self.web3.eth.getTransactionCount(self.main_address) + value
        return nonce

    def _sign_and_send_rawtransaction(self, transaction):
        signed = self.web3.eth.account.signTransaction(transaction, private_key=self._private_key)
        tx_hash = self.web3.toHex(self.web3.eth.sendRawTransaction(signed.rawTransaction))
        return tx_hash

    def transfer_token(self, to_address, value, sum=0):
        """ 代币转账
        :param to_address: 收钱地址
        :param value:  金额
        :return: 交易hash
        """
        to_address = self._valid_address(to_address)
        ush_tx = self.ushtoken_contract.functions.transfer(to_address, value).buildTransaction({
            "nonce": self._nonce(), "gas": self.block_gas_limit, "gasPrice": self.gas_price})
        return self._sign_and_send_rawtransaction(ush_tx)

    def publish_resource(self, udfs_hash, author_address, price, deposit, t=1):
        """ 资源发布

        :param udfs_hash: usfs文件系统hash值
        :param author_address: 资源作者地址
        :param price: 定价,非负int
        :param deposit: 押金,非负int
        :param t: 资源类型, 暂时默认为1
        """
        author_address = self._valid_address(author_address)
        publish_tx = self.centerpublish_contract.functions.createClaim(udfs_hash, author_address, price, deposit,
                                                                       t).buildTransaction({
            "nonce": self._nonce(), "gas": self.block_gas_limit, "gasPrice": self.gas_price})
        return self._sign_and_send_rawtransaction(publish_tx)

    def transfer_tokens(self, addresses, qualitys):
        """ 多地址结算

        :param addresses: List, 结算的地址列表
        :param qualitys: List, 结算地址列表对应的金额
        """
        for i, address in enumerate(addresses):
            addresses[i] = self._valid_address(address)
        publish_tx = self.centerpublish_contract.functions.mulTransfer(addresses, qualitys).buildTransaction({
            "nonce": self._nonce(), "gas": self.block_gas_limit, "gasPrice": self.gas_price})
        return self._sign_and_send_rawtransaction(publish_tx)

    def get_for_receipt(self, tx_hash):
        """ 获取交易回执

        :param tx_hash: 获取交易回执(只有已打包的交易才有数据,否则返回None)
        :return:
        """
        return self.web3.eth.getTransactionReceipt(tx_hash)

    def get_gas_balance(self):
        """ 获取侧链余额

        :rtype: 余额(decimal类型)
        """
        balance = self.web3.eth.getBalance(self.main_address, 'latest')
        return self.web3.fromWei(balance, 'ether')

    def get_token_balance(self, address=None):
        """ 获取代币余额

        :param address: 要查询token余额的地址,默认为当前导入私钥用户的余额
        :return: 代币余额
        """
        address = address if address else self.main_address
        address = self._valid_address(address)
        return self.ushtoken_contract.functions.balanceOf(address).call()

    def transfer_gas(self, to_address, value):
        """

        :param to_address: 接收地址
        :param value: 转账金额(wei)
        :return: 交易hash
        """
        to_address = self._valid_address(to_address)
        payload = {
            'to': to_address, 'value': value, 'gas': self.block_gas_limit, 'gasPrice': self.gas_price,
            'nonce': self._nonce()}
        return self._sign_and_send_rawtransaction(payload)


if __name__ == '__main__':
    c = ContentContract('haibo.json', '12345678')
    c = ContentContract('ulord_testnet_rsk.json', 'tianhe123123')

    # tx_hash = c.transfer_token('0x674F05e1916Abc32a38f40Aa67ae6B503b565999', 1, i)
    print(c.wait_for_receipt(tx_hash='0x67017be6c13eaa76bf60e377a9a147aeebeef44341d603f3b853fd1b6e4a426b'))
    # print(c.get_gas_balance())
    # print(c.get_token_balance("0x411C07f6dE5726A65d107A9B94615daf404c100b"))

    # print(c.publish_resource('123412', '0x674F05e1916Abc32a38f40Aa67ae6B503b565999', 1, 1))
    #  print(c.transfer_tokens(['0x674f05e1916abc32a38f40aa67ae6b503b565999'], [1]))
    # print (c.transfer_gas('0x411C07f6dE5726A65d107A9B94615daf404c100b',c.web3.toWei('1', 'ether')))
    # 0.316084834
