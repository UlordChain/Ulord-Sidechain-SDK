# Ulord - SideChain - SDK

## 快速开始

1. 下载项目
2. 到项目根目录下
```bash
pip install -r requirements.txt

python3 main.py
> help
```

---

## 功能介绍

- 打印帮助信息 	 `help` 
- 退出 	 `exit` 
- 创建新钱包 	 `creat_wallet` 
- 重新加载私钥文件和密码 	 `login_by_key_file` 
- 重新加载私钥 	 `login_by_private_key` 
- 获取侧链余额 	 `get_gas_balance` 
- 交易gas 	 `transfer_gas` 
- 多地址结算 	 `transfer_tokens` 

---

### UDFS

- 修改udfs的ip 	 `set_udfs_ip` 
- 从udfs上下载文件 	 `downloadhash` 
- 上传文件获取hash值 	 `upload` 

---

### 部署一套新的Ushare合约
[相关文档](./deploy.md)
- 部署Ushare合约 	 `deploy_contract`   

---
### 合约调用
- 调用合约 	 `contract 合约名 函数名 参数`   
- 也可以简写为 `合约名 函数名 参数`   
- 获取交易回执 	 `get_receipt` 
- 获取上次合约调用的详细信息 	 `get_last_receipt` 

例如 
- `Token balanceOf 0x...`
- `contract transfer 0x... 100`
- `AuthorModule publish 0x... 20 1`

---
## 使用场景
翻阅[合约API]了解合约功能
1. 使用`deploy_contract`命令一键部署。
2. `Token transfer [0x...] [100]`转币
3. `upload [filepath]`上传一个文件，获得**UDFS**
4. `AuthorModule publish [UDFS] [20] [1]`  发布一个资源，获得一个**资源id**。
5. 其他用户A `UserModule buy [资源id]`购买一个资源，获得**UDFS**。
6. 其他用户A `downloadhash [UDFS]`,下载该资源。