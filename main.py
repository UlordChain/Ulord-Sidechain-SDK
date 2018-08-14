#!/usr/bin/python3
# encoding: utf-8 
# @author  : zza
# @Email   : 740713651@qq.com
# @Time    : 2018/8/9 0009
from ucwallet.ucwallet_cli import cli, UCwallet

if __name__ == '__main__':
    # cli()
    ucwallet = UCwallet(keystorefile=r"./ucwallet/content_contract/resources/keystore/zza.json",
                        keystore_pwd="a1234567")
    # ucwallet.deploy_contract()
    ucwallet._run_cli()
    print(ucwallet._contract("AAAA"))
    # print(ucwallet.contract("Token","balanceOf","0x035EB55d4260455075A8418C4B94Ba618C445537"))
    # print(ucwallet.contract("Token","name"))

