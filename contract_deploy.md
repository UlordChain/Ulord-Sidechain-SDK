# 合约的部署流程  
- [x] 代表部署一个新合约  
- [ ] 代表只是调用合约中的一个方法  
  
  
## 部署说明  
-  首先 , 需要把合约按照顺序部署起来 , 再添加合约之间的访问权限（白名单）  
- 需要准备5个账户地址 , 可重复 , 也可以为部署者地址。    

> 账户地址S = 合约拥有者地址     
> 账户地址A = 团队代币接受地址   
> 账户地址B = 奖励池代币接受地址    
> 账户地址C = 基金会地址  
> 账户地址D = 运营地址  

### 部署代币 UshareToken  
- [x] 部署 UshareToken (无参数)  
- [x] 部署 TeamToken ( UshareToken合约地址 , 账户地址A）  
- [x] 部署 PoolToken ( UshareToken合约地址 , 账户地址B）  
- [ ] 初始化代币分配UshareToken.initialize（账户地址A , 账户地址B , 账户地址C , 账户地址D）  
  
### 部署资源数据库 ClaimDB  
- [x] 部署 DBClaim ( 账户地址S )  
  
###  部署 Payment  
- [x] 部署 Payment ( UshareToken合约地址 , 账户地址S )  

### 部署 InfoDB
- [x] 部署 InfoDB ( 账户地址S )  

### 部署 OrderDB
- [x] 部署 OrderDB ( 账户地址S )  

### 部署 CenterPublish  
- [x] 部署 CenterPublish ( 账户地址B , 账户地址S )  
- [ ] 初始化关联本项目相关合约CenterPublish.initialize（ UshareToken合约地址 , ClaimDB合约地址 , OrderDB合约地址 , InfoDB合约地址 , Payment合约地址 ）  

### 部署 AuthorModule  
- [x] 部署 AuthorModule ( CenterPublish合约地址 , InfoDB合约地址 )  
  
### 部署 AdminModule  
- [x] 部署 AdminModule ( ClaimDB合约地址 , 账户地址S )  
  
### 部署 MulTransfer  
- [x] 部署 CandyUshare ( UshareToken合约地址 , 账户地址S)  
  
### 部署 UserModule  
- [x] 部署 UserModule ( CenterPublish合约地址 , InfoDB合约地址 )  
  
  
## 激活  

1. payment的白名单中添加 center  
> payWhite合约 -> mangeWhiteList ( CenterPublish合约地址 , True )

2. claim的白名单中添加 center  
> ClaimDB合约 -> mangeWhiteList ( CenterPublish合约地址 , True )

3. claim的白名单中添加admin  
> ClaimDB合约 -> mangeWhiteList ( AdminModule合约地址 , True )

4. order的白名单中添加 center  
> OrderDB合约 -> mangeWhiteList ( CenterPublish合约地址 , True )

5. info的白名单中添加 center  
> InfoDB合约 -> mangeWhiteList ( CenterPublish合约地址 , True )

6. center的白名单中添加 author  
> CenterPublish合约 -> mangeWhiteList ( AdminModule合约地址 , True )

7. center的白名单中添加 user  
> CenterPublish合约 -> mangeWhiteList ( UserModule合约地址 , True )

