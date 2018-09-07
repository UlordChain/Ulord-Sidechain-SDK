pragma solidity ^0.4.24;

import "./WhiteMange.sol";
import "./SafeMath.sol";

import "./ClaimDB.sol";
import "./OrderDB.sol";
import "./InfoDB.sol";

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
    using SafeMath for uint256;
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

        if (!claimDb_.isSaleable(_claimId) || claimDb_.getClaimType(_claimId) == 2){
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


    mapping(bytes16 => uint256) public adFee_;
    function renewAD(bytes16 _cid, uint256 _value) public returns(bool){
        if (whitelist_[msg.sender] != true){
          emit LogError(RScorr.Insufficient);
          return false;
        } // 检查调用者白名单权限

        if (claimDb_.getClaimType(_cid) != 2){
            emit LogError(RScorr.InvalidObj);
            return false;
        } //

        adFee_[_cid] = adFee_[_cid].add(_value);
        return true;
    }

    function deductAdFee(bytes16 _cid, uint256 _value) public returns(bool){
        // TODO：需要限制身份
        if(msg.sender != owner && msg.sender != admin){
            emit LogError(RScorr.PermissionDenied);
            return false;
        } // 检查管理员权限

        require(adFee_[_cid] >= _value);
        adFee_[_cid] = adFee_[_cid].sub(_value);
        return true;
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


}