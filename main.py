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
    ucwallet._run_cli()
