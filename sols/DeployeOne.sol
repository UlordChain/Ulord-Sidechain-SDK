pragma solidity ^0.4.24;

import "./UshareToken.sol";
import "./TeamToken.sol";
import "./PoolToken.sol";

import "./ClaimDB.sol";
import "./OrderDB.sol";
import "./InfoDB.sol";
import "./Payment.sol";

import "./MulTransfer.sol";

import "./CenterPublish.sol";
import "./AuthorModule.sol";
import "./UserModule.sol";
import "./AdminModule.sol";

/*
    vm address list:
        0xCA35b7d915458EF540aDe6068dFe2F44E8fa733c
        0x14723A09ACff6D2A60DcdF7aA4AFf308FDDC160C
        0x4B0897b0513fdC7C541B6d9D7E929C4e5364D2dB
        0x583031D1113aD414F02576BD6afaBfb302140225
        0xdD870fA1b7C4700F2BD7f44238821C26f7392148

        0xb49B5ab11b80aD4aE92EFb9E0Bf4a612335129d3
*/

contract DeployOneToken is OwnPlus{
    address public UshareToken_;
    address public TeamToken_;
    address public PoolToken_;

    address public Payment_;
    address public MulTransfer_;

    address  _operation = 0x3f16131aC9203656a9cA790F23878AE165c3eb4f;
    address  _found     = 0x2e836371BF20107837Da6aD9Bb4D08d8F53F65ba;

    address  _team      = 0x24FD610e1769f1f051E6D25A9099588DF13d7FEb;
    address  _pool      = 0x9BaBfBAe60aD466a5b68D29e127bB59429828216;

    address public OwnerAddr_;

    constructor() public {
        OwnerAddr_ = msg.sender;
        UshareToken_ = new UshareToken();
        TeamToken_ = new TeamToken(UshareToken_, _team, OwnerAddr_);
        PoolToken_ = new PoolToken(UshareToken_, _pool, OwnerAddr_);

        // 有个问题。管理员全是这个地址

        //"f8c8765e": "initialize(address,address,address,address)"
        //UshareToken_.call(bytes4(0xf8c8765e),TeamToken_, PoolToken_, _operation, _found);
        UshareToken(UshareToken_).initialize(TeamToken_, PoolToken_, _operation,_pool);

        Payment_ = new Payment(UshareToken_, OwnerAddr_);
        MulTransfer_ = new MulTransfer(UshareToken_, OwnerAddr_);
    }

    bool public initFlag_ = false;
    function init() public{
        require(!initFlag_);
        admin = msg.sender;
        initFlag_ = true;
    }

    // "a8e1fba3": "mangeWhiteList(address,bool)",
    function payWhite(address _target, bool _allow ) onlyAdmin public returns(bool){
        require(Payment(Payment_).mangeWhiteList(_target, _allow));
        return true;
    }

    function mulWhite(address _target, bool _allow) onlyAdmin public returns(bool){
        require(MulTransfer(MulTransfer_).mangeWhiteList(_target, _allow));
        return true;
    }

    function end(address _newAdmin) public onlyAdmin returns(bool){
        Payment(Payment_).transferAdminship(_newAdmin);
        MulTransfer(MulTransfer_).transferAdminship(_newAdmin);
        return true;
    }
}


contract DeployTwoDB is OwnPlus{

    address public ClaimDB_;
    address public OrderDB_;
    address public InfoDB_;

    address public OwnerAddr_;

    constructor() public{
        OwnerAddr_ = msg.sender;
        _deployDB();
    }

    function _deployDB()
         internal
    {
        ClaimDB_ = new ClaimDB(OwnerAddr_);
        OrderDB_ = new OrderDB(OwnerAddr_);
        InfoDB_  = new InfoDB(OwnerAddr_);
     }

    bool public initFlag_ = false;
    function init() public{
        require(!initFlag_);
        admin = msg.sender;
        initFlag_ = true;
    }

    function claimWhite(address _target, bool _allow) onlyAdmin public returns(bool){
        require(ClaimDB(ClaimDB_).mangeWhiteList(_target, _allow));
        return true;
    }

    function orderWhite(address _target, bool _allow) onlyAdmin public returns(bool){
        require(OrderDB(OrderDB_).mangeWhiteList(_target, _allow));
        return true;
    }

    function infoWhite(address _target, bool _allow) onlyAdmin public returns(bool){
        require(InfoDB(InfoDB_).mangeWhiteList(_target, _allow));
        return true;
    }

    function end(address _newAdmin) public onlyAdmin returns(bool){
        ClaimDB(ClaimDB_).transferAdminship(_newAdmin);
        OrderDB(OrderDB_).transferAdminship(_newAdmin);
        InfoDB(InfoDB_).transferAdminship(_newAdmin);
        return true;
    }
}

contract DeployThree is OwnPlus{
    DeployOneToken public DeployTOKEN;
    DeployTwoDB public DeployDB;

    address  _claimPool = 0x9C301D8b430952565aa4233E1B27c5ee50E890bf;

    address public claimDB_;
    address public orderDB_;
    address public infoDB_;

    address public CenterPublish_;
    address public AuthorModule_;
    address public AdminModule_;
    address public UserModule_;

    address public ushareToken_;
    address public payment_;
    address public mulTransfer_;

    address public OwnerAddr_;

    constructor(address _one, address _two) public{
        OwnerAddr_ = msg.sender;

        DeployTOKEN = DeployOneToken(_one);
        DeployDB = DeployTwoDB(_two);

        _getContractAddress();
        _deploy();
        //_deployModule();
    }

    bool public initFlag_ = false;
    function init() public{
        require(!initFlag_);
        admin = msg.sender;
        initFlag_ = true;

        DeployTOKEN.init();
        DeployDB.init();
        _init();
    }

    function _getContractAddress() internal{
        ushareToken_ = DeployTOKEN.UshareToken_();
        payment_ = DeployTOKEN.Payment_();
        mulTransfer_ = DeployTOKEN.MulTransfer_();

        claimDB_ = DeployDB.ClaimDB_();
        orderDB_ = DeployDB.OrderDB_();
        infoDB_  = DeployDB.InfoDB_();
    }


    function _deploy()
        internal
    {
        CenterPublish_ = new CenterPublish(_claimPool, OwnerAddr_);
        AuthorModule_ = new AuthorModule(CenterPublish_, infoDB_);
        UserModule_ = new UserModule(CenterPublish_, infoDB_);
        AdminModule_ = new AdminModule(claimDB_, orderDB_, OwnerAddr_);

    }


    function _init() internal{
        CenterPublish(CenterPublish_).initialize(claimDB_, orderDB_,infoDB_, payment_);

        // 1. payment的白名单中添加 center
        DeployTOKEN.payWhite(CenterPublish_,true);
        // 1. claim的白名单中添加 center
        DeployDB.claimWhite(CenterPublish_, true);
        // 1. claim的白名单中添加admin
        DeployDB.claimWhite(AdminModule_, true);
        // 1. order的白名单中添加 center
        DeployDB.orderWhite(CenterPublish_, true);
        // 1. info的白名单中添加 center
        DeployDB.infoWhite(CenterPublish_, true);

        // 1. center的白名单中添加 author
        centerWhite(AuthorModule_, true);
        // 1. center的白名单中添加 user
        centerWhite(UserModule_, true);

    }

    function centerWhite(address _target, bool _allow) onlyAdmin public returns(bool){
        require(CenterPublish(CenterPublish_).mangeWhiteList(_target, _allow));
        return true;
    }

    function _end(address _newAdmin) internal {
        CenterPublish(CenterPublish_).transferAdminship(_newAdmin);
        AdminModule(AdminModule_).transferAdminship(_newAdmin);
    }

    function end(address _newAdmin) public onlyAdmin returns(bool){
        DeployTOKEN.end(_newAdmin);
        DeployDB.end(_newAdmin);
        _end(_newAdmin);
        return true;
    }

//    function addminWhite(address _target, bool _allow) onlyAdmin public returns(bool){
//        require(AdminModule_.mangeWhiteList(_target, _allow));
//        return true;
//    }

//    function infoWhite(address _target, bool _allow) onlyAdmin public returns(bool){
//        require(InfoDB_.mangeWhiteList(_target, _allow));
//        return true;
//    }
}

