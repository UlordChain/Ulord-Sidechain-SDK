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

}