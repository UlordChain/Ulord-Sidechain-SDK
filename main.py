#!/usr/bin/python3
# encoding: utf-8 
# @author  : zza
# @Email   : 740713651@qq.com
# @Time    : 2018/8/9 0009
import pprint

from web3 import Web3

from ucwallet.ucwallet_cli import cli, UCwallet


def function_test():
    # print(r)
    a = "0x035eb55d4260455075a8418c4b94ba618c445537"
    b = "0x4131c1c06af0474e01e2f71bac418b4178aa883a"
    c = "0xa1b2f3649c2477a65ca9755503d54dee27136044"
    c = UCwallet(keystore_file=r"./ucwallet/content_contract/resources/keystore/zza.json",
                 keystore_pwd="a1234567")
    # 创建账户
    # print(c.creat_wallet("123"))

    # 从钱包文件加载账户
    # print(c.login_by_key_file("zza.json", "a1234567"))

    # 从私钥加载账户
    # private_key = "0x5E610BF3616B268C94C9B94037A5D31CB957D29A79AF404E7EEA1171B72E3D7A"
    # print(c.login_by_private_key(private_key))

    # 转账gas
    # print(c.transfer_gas(b, 1))

    # ERC20
    # 代币转账
    # print(c.contract("Token", "balanceOf", b))
    rece ="0x3e6cb8575b461bdac2c4aa5700bbaa52586b62c9d2464521083242500a400f4d"
    rece = c.contract("Token", "transfer", b, 5000)

    print(rece)
    rece = c.contract("Token", "transfer", b, 5000)
    print(rece)
    # print(c.contract("Token", "balanceOf", b))
    print(c.get_for_receipt(rece))

    # # 授权
    # print(c.contract("Token", "approve", b, 1100))
    #
    # # 授权余额查询
    # print(c.contract("Token", "allowance", a, b))
    #
    # # 授权转账
    # print(c.contract("Token", "approve", a, b, 300))
    # print(c.contract("Token", "allowance", a, b))

    # # 发布资源
    # print(c.publish("QmNuSokP4aMfsbhLQvcGci3NKr9J3mCfp3CrsUzY3efMZG", Web3.toWei(1, "ether"), 0, ))
    #
    # # 放弃资源
    # print(c.abandon("040e9f1fb706e67b58c5e46ffc145ad0"))
    #
    # # 更新资源
    # print(c.update("040e9f1fb706e67b58c5e46ffc145ad0", "QmNuSokP4aMfsbhLQvcGci3NKr9J3mCfp3CrsUzY3efMZG",
    #                Web3.toWei(0, "ether"), )
    #       )
    #
    # # 更新资源价格
    # print(c.update_price("040e9f1fb706e67b58c5e46ffc145ad0", Web3.toWei(1, "ether")))
    #
    # # 转让资源
    # print(c.transfer_claim("040e9f1fb706e67b58c5e46ffc145ad0", "0x70b2cF4605E05da5532A13F2741090893Fc3F396", ))
    #
    # # 根据claim id 查找对应资源信息
    # print(c.find_claim("040e9f1fb706e67b58c5e46ffc145ad0"))
    #
    # # 多地址结算(需要先给此合约地址转账)
    # print(c.pre_multransfer(50000))
    # print(c.add_whitelist())
    # print(c.transfer_tokens(
    #     ["0x70b2cF4605E05da5532A13F2741090893Fc3F396", "0x28b466e7ab8defe97e0fe91e39b66df4f91f9cd2", ],
    #     [Web3.toWei(500, "wei"), Web3.toWei(500, "wei")], )
    # )
    #
    # # 查询当前账户gas余额以及token余额
    # print("Gas: {} ".format(c.gas_balance))
    # print("Token: {} ".format(c.token_balance))
    #
    # # 查询指定地址余额
    # print(c.get_gas_balance("0x761906a41d66bb5f6c7f7588797c1893fa498396"))
    # print(c.get_token_balance("0x761906a41d66bb5f6c7f7588797c1893fa498396"))
    #
    # # 查询回执
    # pprint.pprint(dict(c.get_for_receipt(tx_hash="0x9d86d3b290d3f6231712b262dee22c820628bfcce6ef4b6cee6cdd456bd7076b")))


def main():
    # cli()
    ucwallet = UCwallet(keystore_file=r"./ucwallet/content_contract/resources/keystore/zza.json",
                        keystore_pwd="a1234567")
    ucwallet._run_cli()


if __name__ == '__main__':
    # main()
    function_test()
