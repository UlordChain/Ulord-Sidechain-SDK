#!/usr/bin/python3
# encoding: utf-8 
# @author  : zza
# @Email   : 740713651@qq.com
# @Time    : 2018/8/9 0009

from ucwallet.ucwallet_cli import cli, UCwallet
from eth_abi import decode_single


def function_test():
    a = "0x035eb55d4260455075a8418c4b94ba618c445537"
    b = "0x4131c1c06af0474e01e2f71bac418b4178aa883a"
    # c = "0xa1b2f3649c2477a65ca9755503d54dee27136044"

    ucwallet = UCwallet(keystore_file=r"./ucwallet/content_contract/resources/keystore/zza.json",
                        keystore_pwd="a12345")

    # ucwallet.exit()
    a = ucwallet.deploy_contract()
    # c = ucwallet.contract('AuthorModule', 'publish', 'QmYrxZrFWsxtkhaah1CKuhxCnz5GoQgFPgkYXgmbLueEX3', '0', '1')
    # print(c)
    # while True:
    #     s = ucwallet.get_last_receipt()
    #     print(s)
    #     if s is not None:
    #         break
    # ucwallet.exit()
    #
    # c = ucwallet.contract('AuthorModule', 'claimsByAddress', a)
    # c = ucwallet.contract('AuthorModule', 'myClaims')
    # c = ucwallet.contract('UshareToken', 'balanceOf', a)
    # print(c)
    ucwallet.exit()

    # 帮助信息
    print(ucwallet.help())

    # 查看gas剩余
    print("balance", ucwallet.get_balance())
    print("balance", ucwallet.get_balance(b))

    # 上传文件
    f = ucwallet.upload(r"E:\pythonCode\Ulord-Sidechain-SDK\readme.md")
    print(f)
    # 下载文件
    print(ucwallet.download_hash(f['Hash']))

    # 创建新钱包
    print(ucwallet.create_wallet("b123456789"))

    # 私钥登录
    private_key = "0x93072ba0a53e6da43526b5728b7d029a5abe7f0e806a8d7a50ceb43423df1052"
    print(ucwallet.login_by_private_key(private_key))

    # 钱包文件登录
    file_addr = r"E:\pythonCode\Ulord-Sidechain-SDK\ucwallet\content_contract\resources\keystore\zza.json"
    print(ucwallet.login_by_key_file(file_addr, "a1234567"))

    # 转账gas
    print(ucwallet.transfer_gas(b, 1))
    while True:
        s = ucwallet.get_last_receipt()
        print(s)
        if s is not None:
            break

    # 授权
    print(ucwallet.contract("UshareToken", "approve", b, 1100))
    while True:
        s = ucwallet.get_last_receipt()
        print(s)
        if s is not None:
            break
    # 授权余额查询
    print(ucwallet.contract("UshareToken", "allowance", a, b))

    # 多地址结算(需要先给此合约地址转账)
    print(ucwallet.transfer_tokens(b + "," + c, "10,10"))
    while True:
        s = ucwallet.get_last_receipt()
        print(s)
        if s is not None:
            break

    print(ucwallet.exit())


def main():
    cli()
    # ucwallet = UCwallet(keystore_file=r"./ucwallet/content_contract/resources/keystore/zza.json",
    #                     keystore_pwd="asd")
    # ucwallet._run_cli()
    pass


if __name__ == '__main__':
    main()
    # function_test()
