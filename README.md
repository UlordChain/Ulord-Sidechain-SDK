# Ulord - SideChain - SDK  
  
## 快速开始  

1. 下载项目

2. 准备一个有币的账户。
> 如果账户没有币，我们提供了一些测试账户，不定期往里面转一些测试币。  
> [钱包文件地址](https://github.com/UlordChain/ux-wallet/tree/master/keystore)  
> 密码统一为12345678    

3. 到项目根目录下安装依赖包：
```bash
pip install -r requirements.txt
```

4. 运行程序
```
python3 main.py
# 查看帮助文档
> ucwallet> help
```

 [领取测试链币](http://testnet.usc.ulord.one:8088/faucet)  


---

## 功能介绍

- 打印帮助信息  
> ucwallet> `help`   
- 退出  
> ucwallet> `exit`   
- 创建新钱包  
> ucwallet> `creat_wallet`   
- 重新加载私钥文件和密码  
> ucwallet> `login_by_key_file`   
- 重新加载私钥  
> ucwallet> `login_by_private_key`   
- 获取侧链余额  
> ucwallet> `get_gas_balance`   
- 交易gas  
> ucwallet> `transfer_gas`   
- 多地址结算  
> ucwallet> `transfer_tokens`   
  
---  
  
### UDFS  
  
- 修改udfs的ip  
> ucwallet> `set_udfs_ip`   
- 从udfs上下载文件  
> ucwallet> `downloadhash`   
- 上传文件获取hash值  
> ucwallet> `upload`   
  
---  
  
### 部署一套新的Ushare合约  
  
cli已存在一键部署功能，详细信息请查看[相关文档](./deploy.md)  
- 部署Ushare合约  
> ucwallet> `deploy_contract`     
  
---  
### 合约调用  
  
- 调用合约  
> ucwallet> `contract 合约名 函数名 参数`     
- 也可以简写为 `合约名 函数名 参数` 
> ucwallet> `合约名 函数名 参数`   
- 获取交易回执  
> ucwallet> `get_receipt`   
- 获取上次合约调用的详细信息  
> ucwallet> `get_last_receipt`   
  
例如   
  
- ucwallet> `Token balanceOf 0x...`  
- ucwallet> `contract transfer 0x... 100`  
- ucwallet> `AuthorModule publish 0x... 20 1`  
  
---  
## 使用场景  
翻阅[合约API]了解合约功能  
[]表述需要填写的参数
1. 使用`deploy_contract`命令一键部署。  
2. `Token transfer [0x...] [100]`转币  
3. `upload [filepath]`上传一个文件，获得**UDFS**  
4. `AuthorModule publish [UDFS] [20] [1]`  发布一个资源，获得一个**资源id**。  
5. 其他用户A `UserModule buy [资源id]`购买一个资源，获得**UDFS**。  
6. 其他用户A `downloadhash [UDFS]`,下载该资源。  
  
  
## java版本 
- [ucwallet-sdk](https://github.com/UlordChain/Ulord-platform/blob/wallet_cx/upaas/ucwallet-sdk/ReadMe_zh.md)
- [ucwallet-service](https://github.com/UlordChain/Ulord-platform/blob/wallet_cx/upaas/ucwallet-service/ReadMe_zh.md)
    
