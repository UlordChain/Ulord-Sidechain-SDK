# ulord侧链合约一键部署文档

### 一. 安装solidity 编译器

- [这里](https://github.com/ethereum/solidity/releases)下载对应平台的二进制包(如果页面显示不正常请手动贴入URL刷新)
- 解压添加到系统环境变量中
- 在终端中输入`solc`查看命令是否可用 

### 二. 合约源码已存在于sols目录下

- [这里](./sols)

### 三. 根据官方部署步骤说明 填写配置文件

- [部署步骤说明](./contract_deploy.md)

- 配置文件(需要根据需要修改, 文件格式为`json`)

  ```json
  // deploy: 不是合约时要用到的配置
  // activate: 激活白名单要用到的配置
  {
    "deploy": {
        "account_address": {
          "S": "self",
          "A": "0x035eb55d4260455075a8418c4b94ba618c445537",
          "B": "0x035eb55d4260455075a8418c4b94ba618c445537",
          "C": "0x035eb55d4260455075a8418c4b94ba618c445537",
          "D": "0x035eb55d4260455075a8418c4b94ba618c445537"
        },
        "sortkeys": [
          "UshareToken",
          "ClaimDB",
          "Payment",
          "InfoDB",
          "OrderDB",
          "CenterPublish",
          "AuthorModule",
          "AdminModule",
          "MulTransfer",
          "UserModule"
        ],
          	// 下面为每一个合约部署时, 需要传入的参数, 是一个二位的数组
          	// 数组0: 依赖的前面部署合约的地址, 如果没有, 则为[]
          	// 数组1: 合约构造函数需要的参数
          	// 注意: 所有的价格单位都是wei, 所以在传入值的时候要特别注意
          	// 5 ether == 5 * 10**18  (5乘以10的18次方)
    "UshareToken": [[],[]],
    "TeamToken":[["UshareToken","A","S"],[]],
    "PoolToken":[["UshareToken","B","S"],[]],
    "ClaimDB": [["S"],[]],
    "Payment": [["UshareToken","S"],[]],
    "InfoDB": [["S"],[]],
    "OrderDB":[["S"],[]],
    "CenterPublish": [["B","S"],[]],
    "AuthorModule": [["CenterPublish","InfoDB"],[]],
    "AdminModule": [["ClaimDB","OrderDB","S"],[]],
    "MulTransfer": [["UshareToken","S"],[]],
    "UserModule": [["CenterPublish","InfoDB"],[]]
    //如果某个合约单独部署过, 可以直接填写以前部署过的合约地址作为参数
    //此时会跳过此合约的部署
    //    "UshareToken": "0x7ec2C2f7A9BA7df47B23Df9324e1A24c0c4A1d3f",
    //    "ClaimDB": "0xDeE49196184a7f69C19Bb8fa5CDB794aeb4aec71",
    //    "Payment": "0x6edF6E79f80D9121F349B9AbD1964ff75C2fFd4d", 
    //    "InfoDB": "0x01c4d0F0B2Ea8E1C8Cd0DaCBdDe7A7bA04c4169b", 
    //    "OrderDB": "0x8B821eA33b70FC9Ba9b22D5175457837F3d58320", 
    //    "CenterPublish": "0x25B0920dC0dEf57db665F097727d87fB7310087D",
    //    "AuthorModule": "0x5552Fe772b2e2F65A2238e0e8C17184E06456815",
    //    "AdminModule": "0x3eE65e9c3B05C4e609C0FD324cD975D5aB8d3066",
    //    "MulTransfer": "0x1091ae6a3f4CE005D75207736C0e9ccD7bD87B46",
    //    "UserModule": "0x2B90669B3219643CE328E0519D2d7D25445C68E1"
          },
  "activate": {
        "Payment": ["CenterPublish"],
        "ClaimDB": ["CenterPublish","AdminModule"],
        "OrderDB": ["CenterPublish"],
        "InfoDB": ["CenterPublish"],
        "CenterPublish": ["AdminModule","UserModule"]
      }
  }
  ```


### 四. 程序生成的配置文件路径

包括 abi, bin, 合约地址文件, 钱包文件等

On Windows 7 or 10: `C:\Users\***\AppData\Local\UlordPySdk`

On Mac OS X: `/Users/***/Library/Application Support/UlordPySdk`

On Linux: `/home/***/.local/share/UlordPySdk`