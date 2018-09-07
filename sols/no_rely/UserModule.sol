pragma solidity ^0.4.24;
/**
 * @title 判断错误类型，
 * @dev 避免使用断言抛出异常，直接使用日志输出错误原因，
 * @dev 因为不能直接读取函数的返回值
 * 错误类型说明：
 */
contract ErrorModule {
    enum RScorr { 
        Success,
        Unknown,          // Unknown error
        InvalidAddr,      // 无效的地址
        InvalidStr,       // 无效的字符串
        InvalidClaimId,   // 无效的资源id
        InvalidUdfs,      // 无效的UDFS
        InvalidObj,       // 无效的对象，购买一个已放弃的资源 6

        Unsupported,      // 未授权
        ServStop,         // 服务停止

        ObjNotExist,      // 对象不存在
        ObjExist,         // 对象已存在  10

        ScantToken,       // 代币余额不充足
        ScantCredit,      // 代币授权额度不足
        Insolvent,        // 支付能力不足   13


        Insufficient,     // 白名单权限不足
        PermissionDenied, // 管理权限不足, 管理员权限
        IdCertifyFailed,  // 身份认证失败，作者身份认证

        Insignificance,   // 无意义的操作，更新的内容不变

        ClaimAbandoned,
        CidIsInvalid,
        UdfsInvalid, //udfs 无效
        Undefine01,
        Undefine02,
        Undefine03,
        Undefine04,
        Undefine05,
        Undefine06,
        Undefine07,
        Undefine08,
        Undefine09
    }

    event LogError(RScorr _errorNumber);
}
/**
 * @title OwnBase
 * @dev The OwnBase contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract OwnBase {
    address public owner;

    event LogOwnershipRenounced(address indexed previousOwner);
    event LogOwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );


    /**
     * @dev The OwnBase constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() public {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param _newOwner address : The address to transfer ownership to.
     */
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0));
        emit LogOwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     * @notice Renouncing to ownership will leave the contract without an owner.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     */
    function renounceOwnership() public onlyOwner {
        emit LogOwnershipRenounced(owner);
        owner = address(0);
    }
}


/**
 * @title Ownable
 * @dev Extension for the OwnBase contract, where the ownership needs to be confirmed.
 * This allows the new owner to accept the transfer.
 */
contract Ownable is OwnBase {
    address public newOwner;

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyNewOwner() {
        require(msg.sender == newOwner);
        _;
    }


    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param _newOwner The address to transfer ownership to.
     */
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0));
        newOwner = _newOwner;
    }

    /**
     * @dev Allows the newOwner address to finalize the transfer.
     */
    function acceptOwnership() public onlyNewOwner {
        emit LogOwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}


/**
 * @title 管理员扩展模块
 * @dev 避免单点故障，导致合约管理权限丢失，因此增加一个管理员
 *     推荐一般使用admin，owner作为根权限保存。
 *    owner的权限比admin要高。
 */
contract OwnPlus is Ownable {
    address public admin;

    event LogAdminshipTransferred(address indexed _old, address indexed _new);

    constructor () public {
        admin = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyAdmin() {
        require (msg.sender == owner || msg.sender == admin);
        _;
    }

    /**
     * @dev Allows the current admin to transfer control of the contract to a newadmin.
     * @param _newAdmin address : new admin address
     */
    function transferAdminship(address _newAdmin) onlyAdmin public {
        emit LogAdminshipTransferred(admin, _newAdmin);
        admin = _newAdmin;
    }
}
/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    /**
     * @dev Multiplies two numbers, throws on overflow.
     */
    function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
        // Gas optimization: this is cheaper than asserting 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (_a == 0) {
            return 0;
        }

        c = _a * _b;
        assert(c / _a == _b);
        return c;
    }

    /**
     * @dev Integer division of two numbers, truncating the quotient.
     */
    function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
        // assert(_b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = _a / _b;
        // assert(_a == _b * c + _a % _b); // There is no case in which this doesn't hold
        return _a / _b;
    }

    /**
     * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
        assert(_b <= _a);
        return _a - _b;
    }

    /**
     * @dev Adds two numbers, throws on overflow.
     */
    function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
        c = _a + _b;
        assert(c >= _a);
        return c;
    }
}
/**
 * @title WhiteMange
 * @dev 增加一个白名单列表，方便控制合约权限
 * @dev 反复设置白名单，并不会抛出错误日志。
 */
contract WhiteMange is OwnPlus, ErrorModule{

    /* 控制本合约函数调用权限的白名单列表 */
    mapping (address => bool) public whitelist_;

    event LogWhileChanged(address indexed _target, bool _allow);

    /**
     * @dev 添加或移除一个地址的白名单调用权限
     * @notice  限制为管理员调用。
     * @param _target  address  : 将修改的权限的地址
     * @param _allow   bool     : true代表增加，false代表移除
     * @return         bool     : 操作成功返回true
     */
    function mangeWhiteList(address _target, bool _allow) public returns(bool){
        if(msg.sender != owner && msg.sender != admin){
            emit LogError(RScorr.PermissionDenied);
            return false;
        }// Authority certification

        if (_target == address(0)) {
            emit LogError(RScorr.InvalidAddr);
            return false;
        } // The address cannot be zero

        whitelist_[_target] = _allow;
        emit LogWhileChanged(_target, _allow);
        return true;
    }

    /**
     * @dev 批量增加白名单
     * @notice 只允许管理员调用
     * @param _addresses address[] : 待添加的地址组
     * @return           bool      : 操作成功返回true
     */
    function mulInsertWhite(address[] _addresses) public returns(bool){
        if(msg.sender != owner && msg.sender != admin){
            emit LogError(RScorr.PermissionDenied);
            return false;
        } // Authority certification

        for(uint i = 0; i < _addresses.length; i++){
            // The address cannot be zero
            require(_addresses[i] != address(0));

            whitelist_[_addresses[i]] = true;
            emit LogWhileChanged(_addresses[i], true);
        }

        return true;
    }
}
contract ClaimDB is WhiteMange {
    using SafeMath for uint256;

    struct Claim {
        uint256     initDate;      // date of resource upload
        uint256     deposit;       // declare a deposit required for a resource
        uint256     pricing;       // pricing of resource
        address     author;        // owner of the resource
        uint8       types;          // type of resource
        bool        waive;         // the flag that the author gave up
        string      udfs;          // the HASH value of the resource in the UDFS
    }

    mapping (bytes16 => Claim) private store_;


    /* Successfully claimed a new resource. */
    event LogNewClaim(bytes16 _claimId, address indexed _author);

    /* Update the content of the resource. */
    event LogUpdateClaimUdfs(bytes16 _claimId, address indexed _author, uint256 _pricing);

    /* Update an attribute in a resource. */
    event LogUpdateClaimAuthor(bytes16 _claimId, address indexed _author, address indexed _newAuthor);
    event LogUpdateClaimPricing(bytes16 _claimId, address indexed _author, uint256 _newPricinge);
    event LogUpdateClaimWaive(bytes16 _claimId, address indexed _author, bool _waive);

    /* Delete a resource that has already been claimed. */
    event LogDeleteClaim(bytes16 _claimId);


    /**
     * @dev Constructor.
     * @param _owner address : The address of the contract owner.
     */
    constructor(address _owner) public {
        owner = _owner;
        whitelist_[msg.sender] = true;
    }

    /**
     * @dev Insert a new resource.
     * @param _cid     bytes16  : Resource index(ClaimID).
     * @param _udfs    string   : The UDFS Hash value of the resource.
     * @param _author  address  : Declare the address of the resource.
     * @param _pricing uint256  : Pricing of resources.
     * @param _deposit uint256  : Declare a deposit required for a resource.
     * @param _type    uint8    : Type of resource.
     * @return         bool     : The successful call returns true.
     */
    function insertClaim(bytes16 _cid, string _udfs, address _author, uint256 _pricing, uint256 _deposit, uint8 _type)
        public
        returns(bool)
    {
        if (whitelist_[msg.sender] != true){
            emit LogError(RScorr.Insufficient);
            return false;
        } // Check the caller's whitelist permission.

        if (isExist(_cid)){
            emit LogError(RScorr.ObjExist);
            return false;
        } // Check if the resource exists.

        store_[_cid].author    = _author;
        store_[_cid].udfs      = _udfs;
        store_[_cid].initDate  = now;
        store_[_cid].deposit   = _deposit;
        store_[_cid].pricing   = _pricing;
        store_[_cid].waive     = false;
        store_[_cid].types      = _type;

        emit LogNewClaim(_cid, _author);

        return true;
    }

    /**
     * @dev Update the content of the resource (UDFS hash) and the pricing.
     * @param _cid       bytes16  : Resource index(ClaimID).
     * @param _author    address  : Declare the address of the resource.
     * @param _udfs      string   : The UDFS Hash value of the resource.
     * @param _pricing   uint256  : New pricing of resources.
     * @return           bool     : The successful call returns true.
     */
    function updateClaim(bytes16 _cid, address _author, string _udfs, uint256 _pricing)
        public
        returns(bool)
    {
        if (whitelist_[msg.sender] != true){
            emit LogError(RScorr.Insufficient);
            return false;
        } // Check the caller's whitelist permission.

        if(store_[_cid].author != _author) {
            emit LogError(RScorr.IdCertifyFailed);
            return false;
        } // Verify that the resource is the caller's.


        store_[_cid].udfs    = _udfs;
        store_[_cid].pricing = _pricing;

        emit LogUpdateClaimUdfs(_cid, _author, _pricing);

        return true;
    }


    /**
     * @dev Update the author address of the resource.
     * @param _cid       bytes16  : Resource index(ClaimID).
     * @param _author    address  : Claim the address of the resource.
     * @param _newAuthor address  : New owners of resources.
     * @return           bool     : The successful call returns true.
     */
    function updateClaimAuthor(bytes16 _cid, address _author, address _newAuthor)
        public
        returns(bool)
    {
        if (whitelist_[msg.sender] != true){
            emit LogError(RScorr.Insufficient);
            return false;
        } // Check the caller's whitelist permission.

        if(store_[_cid].author != _author) {
            emit LogError(RScorr.IdCertifyFailed);
            return false;
        } // Verify that the resource is the caller's.

        if(_newAuthor == address(0)) {
            emit LogError(RScorr.InvalidAddr);
            return false;
        } // The owner of the resource cannot be empty.

        if(store_[_cid].author == _newAuthor){
            emit LogError(RScorr.Insignificance);
            return false;
        } // The updated content should not be the same.

        emit LogUpdateClaimAuthor(_cid, _author, _newAuthor);

        store_[_cid].author = _newAuthor;
        return true;
    }


    /**
     * @dev Update the pricing of the resource.
     * @param _cid        bytes16  : Resource index(ClaimID).
     * @param _author     address  : Claim the address of the resource.
     * @param _newPricing address  : New pricing of resources.
     * @return            bool     : The successful call returns true.
     */
    function updateClaimPricing(bytes16 _cid, address _author, uint256 _newPricing)
        public
        returns(bool)
    {
        if (whitelist_[msg.sender] != true){
            emit LogError(RScorr.Insufficient);
            return false;
        } // Check the caller's whitelist permission.

        if(store_[_cid].author != _author){
            emit LogError(RScorr.IdCertifyFailed);
            return false;
        } // Verify that the resource is the caller's.

        if(store_[_cid].pricing == _newPricing){
            emit LogError(RScorr.Insignificance);
            return false;
        } // The updated content should not be the same.

        emit LogUpdateClaimPricing(_cid, _author, _newPricing);

        store_[_cid].pricing = _newPricing;
        return true;
    }

    /**
     * @dev The author abandons a resource.
     * @notice Canceling resource abandonment cannot be invoked by the author.
     * @param _cid     bytes16  : Resource index(ClaimID).
     * @param _author  address  : Claim the address of the resource.
     * @param _waive    bool    : True means give up, false means cancel.
     * @return          bool    : The successful call returns true.
     */
    function updateClaimWaive(bytes16 _cid, address _author, bool _waive)
        public
        returns(bool)
    {
        if (whitelist_[msg.sender] != true){
            emit LogError(RScorr.Insufficient);
            return false;
        } // Check the caller's whitelist permission.

        if(store_[_cid].author != _author) {
            emit LogError(RScorr.IdCertifyFailed);
            return false;
        } // Verify that the resource is the caller's.

        if(store_[_cid].waive == _waive) {
            emit LogError(RScorr.Insignificance);
            return false;
        } // The updated content should not be the same.

        emit LogUpdateClaimWaive(_cid, _author, _waive);
        store_[_cid].waive = _waive;
        store_[_cid].deposit = 0;

        return true;
    }

    /**
     * @dev Admin delete resources.
     * @notice This function is limited to calls only by the admin or owner.
     * @param _cid      bytes16  : Resource index(ClaimID).
     * @return          bool     : The successful call returns true.
     */
    function deleteClaim(bytes16 _cid)
        public
        returns(bool)
    {
        if(msg.sender != owner && msg.sender != admin){
            emit LogError(RScorr.PermissionDenied);
            return false;
        } // Check if the caller is an administrator.

        if(store_[_cid].author == address(0)) {
            emit LogError(RScorr.ObjNotExist);
            return false;
        } // Check if the resource exists.

        delete store_[_cid];

        emit LogDeleteClaim(_cid);

        return true;
    }

    /////////////////////////
    /// View
    /////////////////////////

    /**
     * @dev Find details of a specified resource
     * @notice Only allowed to be called by the address in the whitelist.
     * @param _claimId   bytes16 : Resource index(ClaimID).
     * @return                   : Specify the resource details.
     *                    author : owner of the resource
     *                      udfs : the HASH value of the resource in the UDFS
     *                  initDate : release time
     *                   deposit : declare a deposit required for a resource
     *                   pricing : pricing
     *                     waive : the flag that the author gave up
     *                     types : type of resource
     */
    function getClaimInfoByID(bytes16 _claimId) public view returns(
        address author,   string udfs, uint256 initDate, uint256 deposit,
        uint256 pricing,  bool  waive, uint8   types)
    {
//        if(store_[_claimId].author == address(0) || whitelist_[msg.sender] == false) {
//            return (0,"Null",0,0,0,true,0);
//        }

        return (store_[_claimId].author,
        store_[_claimId].udfs,
        store_[_claimId].initDate,
        store_[_claimId].deposit,
        store_[_claimId].pricing,
        store_[_claimId].waive,
        store_[_claimId].types);
    }


    /**
     * @dev Check if the resource exists
     * @param _claimId bytes16  : Resource index(ClaimID).
     * @return            bool  : True means resources exist
     */
    function isExist(bytes16 _claimId)
        view
        public
        returns(bool)
    {
        if (store_[_claimId].author != address(0)){
            return true;
        }
        return false;
    }


    /**
     * @dev Check if resources can be purchased
     *  1. Resources do not exist.
     *  2. When the pricing is zero, it means free
     *  3. When the waive is true ，the author has removed this resource.
     * @param _claimId bytes16  : Resource index(ClaimID).
     * @return         bool     : True is purchasable.
     */
    function isSaleable(bytes16 _claimId)
        view
        public
        returns(bool)
    {
        if (store_[_claimId].author == address(0) ||
        store_[_claimId].pricing == 0             ||
        store_[_claimId].waive   == true)
        {
            return false;
        }
        return true;
    }


    /**
     * @dev Get purchase information for the resource.
     * @notice It is recommended to judge with `isSaleable` first.
     * @param _claimId bytes16  : Resource index(ClaimID).
     * @return                  : Purchasing resources is required information.
     *          author address  : Owner of the resource.
     *         pricing uint256  : Pricing of resource.
     */
    function getGoodsInfo(bytes16 _claimId)
        view
        public
        returns(address author, uint256 pricing)
    {
        return (store_[_claimId].author, store_[_claimId].pricing);
    }

    /**
     * @dev Get purchase information for the resource.
     * @param _claimId bytes16  : Resource index(ClaimID).
     * @return                  : Purchasing resources is required information.
     *          author address  : Owner of the resource.
     */
    function getDeposit(bytes16 _claimId)
        view
        public
        returns(uint256 deposit)
    {
        return store_[_claimId].deposit;
    }


//    /**
//     * @dev Get pricing for resources
//     * @param _claimId bytes16 : Resource index(ClaimID)
//     * @return Pricing of resources
//     */
//    function getGoodsPricing(bytes16 _claimId)
//        view
//        public
//        returns(uint256 pricing)
//    {
//        return store_[_claimId].pricing;
//    }

}/**
 * @title InfoDB
 * @dev Used to query.
 * @notice Whitelist permission is required for data writing
 */
contract InfoDB is WhiteMange{

    // list最多存多少, 循环最多一次uint8=256
    // list本身没限制，查询也没限制
    // list分批查询问题，先不管这个问题
    // TODO:当一个列表比较大的时候，怎么有效的查询（>10000）

    struct stUserInfo{
        //uint256 orderCnt;
        bytes32[] orderList;   // All orders from user.
        bytes16[] goodsList;   // Users have purchased all resources.
    }

    struct stAuthorInfo{
        bytes16[] claims;       // All resources published by the author
    }

    struct stClaimInfo{
        mapping(address => bytes32) bought; // Query the order by a user on this resource.
        address[] buyers;                   // All users from resources.
        bytes32[] orderList;                // All orders for this resource
    }

    mapping(address => stUserInfo) user_;
    mapping(bytes16 => stClaimInfo) claim_;
    mapping(address => stAuthorInfo) author_;

    constructor (address _owner) public {
        owner = _owner;
    }

    /**
     * @dev Record an order.
     * @param _oId   bytes32  : Orders index(OrderID).
     * @param _cid   bytes16  : Resource index(ClaimID).
     * @param _buyer address  : Buyer's address
     * @return       bool     : The successful call returns true.
     */
    function insertOrder(bytes32 _oId, bytes16 _cid, address _buyer)
        public
        returns(bool)
    {
        if (whitelist_[msg.sender] != true){
            emit LogError(RScorr.Insufficient);
            return false;
        } // Check the caller's whitelist permission.

        user_[_buyer].orderList.push(_oId);
        user_[_buyer].goodsList.push(_cid);
        // 记录资源的购买者
        claim_[_cid].buyers.push(_buyer);
        // 建立购买索引
        claim_[_cid].bought[_buyer] = _oId;

        return true;
    }

    /**
     * @dev Record a resource generation.
     * @param _cid    bytes16  : Resource index(ClaimID).
     * @param _author address  : Authors' address
     * @return        bool     : The successful call returns true.
     */
    function insertClaim(bytes16 _cid, address _author)
        public
        returns(bool)
    {
        if (whitelist_[msg.sender] != true){
            emit LogError(RScorr.Insufficient);
            return false;
        } // Check the caller's whitelist permission.

        author_[_author].claims.push(_cid);
        return true;
    }

    /////////////////////////
    /// View
    /////////////////////////

    /**
     * @dev Query all resources the author has published.
     * @param _author  address   : Author's address
     * @return         bytes16[] : claimID组成的bytes16的列表
     */
    function getClaimsByAuthor(address _author) view public returns(bytes16[]){
        return author_[_author].claims;
    }

    /**
     * @dev Query all resources that the user has purchased.
     * @param _user    address   : Author's address
     * @return         bytes16[] : claimID组成的bytes16的列表
     */
    function getClaimsByUser(address _user) view public returns(bytes16[]){
        return user_[_user].goodsList;
    }

    /**
     * @dev 查询用户的所有的订单
     * @param _buyer   address   : User's address
     * @return         bytes32[] : orderID组成的bytes32的列表
     */
    function getOrdersByUser(address _buyer) view public returns(bytes32[]){
        return user_[_buyer].orderList;
    }

    /**
     * @dev 查询资源的所有的购买者
     * @param _cid     bytes16   : 资源索引 claimID
     * @return         address[] : 地址组成的列表
     */
    function getConsumerByClaim(bytes16 _cid) view public returns(address[]){
        return claim_[_cid].buyers;
    }


    //TODO:要不要这个查询
    /// 查询资源的所有订单
//    function getOrdersByClaim(bytes16 _cid) view public returns(){
//        return claim_[_cid][orderList];
//    }


    /**
     * @dev Query whether a particular user has purchased a resource
     * @param _buyer address : User's address
     * @param _cid bytes16   : 资源id
     * @return bool          : 已购买返还true，未购买返回false;
     */
    function isBought(address _buyer, bytes16 _cid) view public returns(bool){
        // 查询用户在此资源下是否存在订单
        if (claim_[_cid].bought[_buyer] == 0 ){
            return false;
        }
        return true;
    }
}
contract OrderDB is WhiteMange {
    struct Order {
        //赠送问题，折扣,批量购买
        uint256    time;       // 时间
        uint256    price;      // 定价
        uint256    cost;       // 实际花费
        address    customer;   // 顾客
        address    payer;      // 付款方
        bytes16    claimId;    // 资源id
    }

    mapping (bytes32 => Order) public store_;


    event LogNewOrder(
        bytes32 orderId,
        bytes16 claimId,
        address indexed customer,
        address indexed payer
    );
    event LogRemoveOrder(bytes32 orderId);


    constructor(address _owner) public{
        owner = _owner;
    }

    /**
     * @dev 插入一个新的订单
     * @param _orderId  bytes32 : 订单ID
     * @param _customer address : 顾客
     * @param _claimId  bytes16 : 资源id
     * @param _price    uint256 : 定价
     * @param _payer    address : 支付地址
     * @param _cost     uint256 : 支付代币数量
     * @return          bool    : 操作成功返回true
     */
    function insert(bytes32 _orderId, address _customer,bytes16 _claimId,
                    uint256 _price, address _payer, uint256 _cost)
        public
        returns(bool)
    {
        if (whitelist_[msg.sender] != true){ 
            emit LogError(RScorr.Insufficient);
            return false;
        } // Check the caller's whitelist permission.

        if (isExist(_orderId)){
            emit LogError(RScorr.ObjExist);
            return false;
        } // Check if the resource exists.

        store_[_orderId] = Order({
            time     : now, 
            price    : _price, 
            cost     : _cost, 
            customer : _customer,
            payer    : _payer, 
            claimId  :_claimId
        });

        // store_[_orderId] = Order(now,_price,_cost,_customer,_payer,_claimid);

        emit LogNewOrder(_orderId, _claimId, _customer, _payer);
        return true;
    }

    /**
     * @dev 删除一个订单
     * @notice 只能由管理员删除
     * @param _orderId bytes32 : 订单ID
     * @return         bool    : 操作成功返回true
     */
    function remove(bytes32 _orderId) public returns(bool) {
        if(msg.sender != owner && msg.sender != admin){ 
            emit LogError(RScorr.PermissionDenied);
            return false;
        } // 检查管理员权限

        if(store_[_orderId].time == 0){ 
            emit LogError(RScorr.ObjNotExist);
            return false;
        } // 检查资源是否存在

        delete store_[_orderId];
        
        emit LogRemoveOrder(_orderId);

        return true;
    }



    // function delete() public returns(bool){}

    // function update() public returns(bool){}

    // function find() public returns(bool){}


    /////////////////////////
    /// View
    /////////////////////////

    /**
     * @dev 判断订单是否存在
     * @param _orderId bytes32 : 订单id
     * @return         bool    : 存在返回true, 不存在返回false
     */
    function isExist(bytes32 _orderId) view public returns(bool){
        if (store_[_orderId].time != 0) {
            return true;
        }
        return false;
    }

    /**
     * @dev 获取订单的详细信息
     * @param _orderId bytes32  : 订单ID
     * @return                  : 订单的详细信息
     *         time             ：创建时间
     *         price            : 定价
     *         cost             : 实际花费
     *         customer         : 顾客
     *         payer            : 支付地址
     *         claimId          : 商品ID（ClaimID）
     */
    function getOrderInfoByID(bytes32 _orderId) view public returns(
        uint256 time,     uint256 price,  uint256 cost,
        address customer, address payer,  bytes16 claimId)
    {
        if (store_[_orderId].time == 0){
            return (0, 0, 0, 0, 0, 0);
        }

        return(
            store_[_orderId].time,
            store_[_orderId].price,
            store_[_orderId].cost,
            store_[_orderId].customer,
            store_[_orderId].payer,
            store_[_orderId].claimId
        );
    }
}



//TODO: TO modify ERC20 to GAS;

/*
    支付验证：
    1. 保证资源存在，避免对无效的资源付费
    2. 检查定价不为0，定价为0的资源，不需要付费
    3. 检查资源是否已经放弃，放弃的资源不能购买，资源下架，保证已购买的用户能继续查看
    4. 检查订单是否已存在，避免反复购买
    5. 检查支付地址的购买能力
*/

/**
 * @title 中心合约
 * @dev 本合约起一个纽带作用
 * @notice 合约中
 */
contract CenterControl is WhiteMange{

    //Payment public pay_;

    ClaimDB public claimDb_;
    OrderDB public orderDb_;
    InfoDB  public infoDb_;

    // 资源押金，由管理员设置
    uint256 public claimDeposit_ = 0;
    address public claimPool_;

    event LogSimpleClaim(address indexed author, string udfs);

    /**
     * @dev constructor
     * @param _pool  address : 押金池地址
     * @param _owner address : The address of the contract owner.
     */
    constructor (address _pool, address _owner)
        public
    {
        owner = _owner;
        claimPool_ = _pool;
    }

    /**
     * @dev Initialization function,related contract of the project
     * @notice Can only be called once by the owner.
     * @param _claim address : ClaimDB's contract address
     * @param _order address : OrderDB's contract address
     * @param _info  address : InfoDB's contract address
     * @return       bool    : The successful call returns true.
     */
    function initialize(address _claim, address _order, address _info) onlyAdmin
        public
        returns(bool)
    {
        require(claimDb_ == address(0), "You can only call it once");
        require(_claim != address(0)  && _order  != address(0)
                && _info != address(0) , "contract address cannot be 0.");

        claimDb_ = ClaimDB(_claim);
        orderDb_ = OrderDB(_order);
        infoDb_  = InfoDB(_info);

        return true;
    }

    // TODO：收的押金的数量，把钱转移到一个更安全的地方。
    // 岂不是可以随便拿走这笔钱么
    function () payable public {
        // 只允许迁移的时候，管理才能动这笔钱。
    }

//    /// withdraw
//    function withdraw()  public onlyOwner returns(bool){
//        (msg.sender).transfer(address(this).balance);
//        return true;
//    }


    // TODO：迁移合约，升级的时候使用。
    function migrate(address _newCenter) public onlyOwner returns(bool){
        // 迁移的是时候可能需要一些其他的操作，待添加
        _newCenter.transfer(address(this).balance);
        return true;
    }

    /**
     * @dev  申明一个新资源
     * @param _udfs    string  : 资源的UDFS Hash值
     * @param _author  address : 发布者的地址
     * @param _price   uint256 : 资源的定价
     * @param _type    uint8   : 资源的类型，现阶段默认为1
     * @param _storage bool    : 是否存数据库，true,代表储存，false合约将不记录任何数据。
     * @return         bool    : 操作成功返回true
     */
    function createClaim(string _udfs, address _author, uint256 _price, uint8 _type, bool _storage)
        public
        returns(bool)
    {
        if (whitelist_[msg.sender] != true){
            emit LogError(RScorr.Insufficient);
            return false;
        }

        if (_storage == false){
            emit LogSimpleClaim(_author, _udfs);
            return false;
        }

        bytes16 _claimId = bytes16(keccak256(abi.encodePacked(_udfs , _author)));
        if (claimDb_.isExist(_claimId)){
            emit LogError(RScorr.ObjExist);
            return false;
        } /* Check if the resource exists */


        require(claimDb_.insertClaim(_claimId, _udfs, _author, _price, claimDeposit_, _type));

        require(infoDb_.insertClaim(_claimId, _author));

        return false;

    }

    /**
     * @dev  创建一个新订单
     * @param _customer address : 购买者地址
     * @param _claimId  bytes16 : 商品ID
     * @param _payer    address : 支付者地址
     * @param _price    uint256 : 定价
     * @return          bool    : 操作成功返回true
     */
    function createOrder(address _customer,bytes16 _claimId, uint256 _value, address _payer, uint256 _price)
        public
        returns(bool)
    {
        if (whitelist_[msg.sender] != true){
            emit LogError(RScorr.Insufficient);
            return false;
        } // Check the caller's whitelist permission.

        if (!claimDb_.isSaleable(_claimId)){
            emit LogError(RScorr.InvalidObj);
            return false;
        } //

        if(_value < _price){
            emit LogError(RScorr.Insolvent);
            return false;
        }

        // 生成订单id
        bytes32 _orderId = bytes32(keccak256(abi.encodePacked(_customer , _claimId)));

        // 生成订单
        if (orderDb_.insert(_orderId, _customer, _claimId, _price, _payer, _price)){
            require(infoDb_.insertOrder(_orderId, _claimId, _payer));
            return true;
        }else{
            return false;
        }
    }

    ///@dev 更新资源内容和价格
    function updateClaim(bytes16 _cid, address _author, string _newudfs, uint256 _newprice)
        public
        returns(bool)
    {
        if (whitelist_[msg.sender] != true){ 
          emit LogError(RScorr.Insufficient);
          return false;
        } // 检查调用者白名单权限

        return claimDb_.updateClaim(_cid, _author, _newudfs, _newprice);
    }

    ///@dev 变更资源作者，交易版权
    function updateClaimAuthor(bytes16 _cid, address _author, address _newAuthor)
        public
        returns(bool)
    {
        if (whitelist_[msg.sender] != true){ 
          emit LogError(RScorr.Insufficient);
          return false;
        } // 检查调用者白名单权限

        return claimDb_.updateClaimAuthor(_cid, _author, _newAuthor);
    }

    ///@dev 变更资源的定价
    function updateClaimPrice(bytes16 _cid, address _author, uint256 _newprice)
        public
        returns(bool)
    {
        if (whitelist_[msg.sender] != true){ 
          emit LogError(RScorr.Insufficient);
          return false;
        } // 检查调用者白名单权限

        return claimDb_.updateClaimPricing(_cid, _author, _newprice);
    }

    ///@dev 放弃资源，作者模块只能放弃，管理员能取消资源放弃。
    function updateClaimWaive(bytes16 _cid, address _author, bool _waive)
        public
        returns(bool)
    {
        if (whitelist_[msg.sender] != true){ 
          emit LogError(RScorr.Insufficient);
          return false;
        } // 检查调用者白名单权限

        uint256 _deposit = claimDb_.getDeposit(_cid);

        if(claimDb_.updateClaimWaive(_cid, _author, _waive)){
            //退押金
            // 获取押金的数量和对象，对象已有。
            if(_deposit != 0){
                _author.transfer(_deposit);
            }
            return true;
        }
        return false;
    }


    /**
     * @dev 设置发布资源的押金
     * @notice 需要管理员权限
     * @param _newDeposit uint256 ： 发布一个资源所需的押金
     */
    function setClaimDeposit(uint256 _newDeposit)
        public
        returns(bool)
    {
        if(msg.sender != owner && msg.sender != admin){ 
            emit LogError(RScorr.PermissionDenied);
            return false;
        } // 检查管理员权限

        if(_newDeposit == claimDeposit_){
            emit LogError(RScorr.Insignificance);
            return false;
        } // 跟新的价格与原来不一样

        claimDeposit_ = _newDeposit;

        return true;
    }


    /////////////////////////
    /// Internal
    /////////////////////////

    ///@dev 根据ClaimId查找资源的详细信息
    function getClaimDetails(bytes16 _cid)
        view public returns(
            address author,  string  udfs,  uint256 initDate,
            uint256 deposit, uint256 price, bool waive,  uint8   types)
    {
        return claimDb_.getClaimInfoByID(_cid);
    }

    ///@dev 根据OrderId查找订单的详细信息
    function getOrderDetails(bytes32 _oid)
        view public returns(
            uint256 time,     uint256 price,  uint256 cost,
            address customer, address payer,  bytes16 claimId)
    {
        return orderDb_.getOrderInfoByID(_oid);
    }


    ///@dev 获取订单的基本信息
    function getGoodsInfo(bytes16 _claimId)
        view
        public
        returns(address author, uint256 pricing)
    {
        return claimDb_.getGoodsInfo(_claimId);
    }


    ///////////////////
    /// Internal
    ///////////////////


//    /**
//     * @dev 检查订单生成条件和付款人能否购买。
//     * @param _oID   bytes32 : 订单ID
//     * @param _payer address ：付款人地址
//     * @param _cost  uint256 : 付款金额
//     * @return bool          : 满足支付条件返回true
//     */
//    function _checkBuy(bytes32 _oID, address _payer, uint256 _cost)
//        internal
//        returns(bool)
//    {
//        // 判断订单是否存在，避免反复购买
//        if (orderDb_.isExist(_oID)){
//            emit LogError(RScorr.ObjExist);
//            return false;
//        }
//
//        // 检查付款者的购买能力
//        if (!pay_.isPayable(_payer, _cost)){
//            emit LogError(RScorr.Insolvent);
//            return false;
//        }
//
//        return true;
//    }


}contract UserModule{
    using SafeMath for uint256;

    CenterControl public Center_;
    InfoDB public Info_;

    /**
     * @dev 构造函数
     * @param _center address : 中心合约地址
     * @param _info   address : 信息数据合约地址
     */
    constructor (address _center, address _info) public {
        Center_ = CenterControl(_center);
        Info_   = InfoDB(_info);
    }

    /**
     * @dev 购买资源
     * @param _claimId bytes16 : 资源id
     * @return         bool    : 操作成功返回true
     */
    function buy(bytes16 _claimId)
        public
        payable
        returns(bool)
    {
        return _buyCore(msg.sender, _claimId, msg.sender, msg.value);
    }

    /**
     * @dev 购买资源赠送给指定地址
     * @param _claimId bytes16 : 资源id
     * @param _donee   address : 受赠地址
     * @return         bool    : 操作成功返回true
     */
    function buyTo(bytes16 _claimId, address _donee)
        public
        payable
        returns(bool)
    {
        return _buyCore(_donee, _claimId, msg.sender, msg.value);
    }

    function _buyCore(address _customer, bytes16 _cid, address _payer, uint256 _value)
        internal
        returns(bool)
    {
        (address _author,uint256 _price) = Center_.getGoodsInfo(_cid);

        if (Center_.createOrder(_customer, _cid, _value, _payer, _price) == true){
            _author.transfer(_price);
            _payer.transfer(_value.sub(_price));
            return true;
        }else{
            _payer.transfer(_value);
            return false;
        }
    }


    /////////////////////////
    /// View
    /////////////////////////

    /**
     * @dev 查询用户自己已经购买的资源
     * @return claims bytes16[] : 由claimID组成的列表
     */
    function myGoods() view public returns(bytes16[])
    {
        return Info_.getClaimsByUser(msg.sender);
    }

    /**
     * @dev 查询用户自己所有的订单
     * @return claims bytes32[] : 由orderID组成的列表
     */
    function myOrders() view public returns(bytes32[])
    {
        return Info_.getOrdersByUser(msg.sender);
    }

    /**
     * @dev 获取订单的详细信息
     * @param _orderId bytes32  : 订单ID
     * @return                  : 订单的详细信息
     *         time     uint256 : 创建时间
     *         price    uint256 : 定价
     *         cost     uint256 : 实际花费
     *         customer address : 顾客
     *         payer    address : 支付地址
     *         claimId  types16 : 商品ID（ClaimID）
     */
    function findOrderInfo(bytes32 _orderId) view public returns(
        uint256 time,     uint256 price,  uint256 cost,
        address customer, address payer,  bytes16 claimId)
    {
        return Center_.getOrderDetails(_orderId);
    }



    /////////////////////////
    /// Internal Function
    /////////////////////////

    /**
     * @dev 简单的检查一下HASH串的有效性
     * @param _input string  : 待检测的字符串
     * @return bool          : 检测通过返回true
     */
    function _hashFilter(string _input) pure internal returns(bool){
        bytes memory _temp = bytes(_input);

        // length == 46 , Qm~
        if (_temp.length == 46 &&
            _temp[0] == 0x51   &&
            _temp[1] == 0x6D   ){
            return true;
        }
        return false;
    }

}
