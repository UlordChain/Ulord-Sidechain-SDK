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



