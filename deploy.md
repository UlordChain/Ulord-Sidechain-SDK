# ulord侧链合约一键部署文档

### 一. 安装solidity 编译器

- [这里](https://github.com/ethereum/solidity/releases)下载对应平台的二进制包(如果页面显示不正常请手动贴入URL刷新)
- 解压添加到系统环境变量中
- 在终端中输入`solc`查看命令是否可用 

### 二. 在官方开源项目中下载所有合约源码

- [这里](http://192.168.14.240:3000/liuqiping/Ushare/)

### 三. 根据官方部署步骤说明 填写配置文件

- [部署说明文档](http://192.168.14.240:3000/liuqiping/Ushare/src/master/docs/deploy.md)

- 配置文件(需要根据需要修改, 文件格式为`json`)

  ```json
  // deploy: 不是合约时要用到的配置
  // activate: 激活白名单要用到的配置
  {
      "deploy": {
              "sortkeys": [  //sortkeys: 要部署合约的顺序
                  "Token",
                  "ClaimDB",
                  "OrderDB",
                  "Payment",
                  "CenterPublish",
                  "AuthorModule",
                  "AdminModule",
                  "MulTransfer"
              ],
          	// 下面为每一个合约部署时, 需要传入的参数, 是一个二位的数组
          	// 数组0: 依赖的前面部署合约的地址, 如果没有, 则为[]
          	// 数组1: 合约构造函数需要的参数
          	// 注意: 所有的价格单位都是wei, 所以在传入值的时候要特别注意
          	// 5 ether == 5 * 10**18  (5乘以10的18次方)
          	"Token": [[], [50000000000000000000000000, "BlogDemo", 18, "BD"]],  //总量 5千万个BD
              "ClaimDB": [[], []],
              "OrderDB": [[], []],
              "Payment": [["Token"], []],
              "CenterPublish": [
                  ["Token", "ClaimDB", "OrderDB", "Payment"],
                  ["0x761906A41D66Bb5f6c7F7588797C1893fa498396"]
              ],
              "AuthorModule": [["CenterPublish"], []],
              "AdminModule": [["ClaimDB"], []],
              "MulTransfer": [["Token"], []]
          	
          	//如果某个合约单独部署过, 可以直接填写以前部署过的合约地址作为参数
          	//此时会跳过此合约的部署
              //"Token": "0x8085eb638fD791BCb0b91fc95F943a32db1845Fe",
              //"ClaimDB": "0x5d12DD4516DE35a82A0DBd1Aa8568Cb65FcD223D",
              //"OrderDB": "0x5B6e13c49E647Fab6aDFF0817D8E44DfbffF8f08",
              //"Payment": "0x7B0a4eccaA9a6e52736b0fb6103FD6e7279Fb2fe",
              //"CenterPublish": "0x154C72f37ADdC5D1147a6eC12FFed60C6314A4Aa",
              //"AuthorModule": "0x792B13493Fec7E4D9b41c663897956F89C424d0f",
              //"AdminModule": "0x6202491D37C9Ed4816E3E29AFBd8BfE2047Ef86d",
              //"MulTransfer": "0xd95E0806e7063567Fb2dB5023b18765cFE4d09A6"
          },
      "activate":{
          "ClaimDB":["CenterPublish"],  // 在ClaimDB中激活CenterPublish白名单成员
          "CenterPublish":["AuthorModule"],  //同上
          "Payment":["AuthorModule"]  // 同上
      }
  }
  ```



### 四. 运行程序

修改参数:

- config: 配置文件路径
- spath: 合约源文件所在目录
- provider: 提供者(需要连接到区块链网络的地址)
- privateKey: 用来部署合约的私钥(**与下面参数二选一**)
  - keystorefile: 钱包文件路径
  - keystore_pwd: 钱包文件密码

运行程序: `python deploy_contract.py`

### 五. 程序生成的配置文件路径

包括 abi, bin, 合约地址文件, 钱包文件等

On Windows 7 or 10: `C:\Users\***\AppData\Local\UlordPySdk`

On Mac OS X: `/Users/***/Library/Application Support/UlordPySdk`

On Linux: `/home/***/.local/share/UlordPySdk`