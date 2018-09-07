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
/**
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
