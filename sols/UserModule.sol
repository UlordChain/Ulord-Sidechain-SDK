pragma solidity ^0.4.24;

import "./SafeMath.sol";
import "./CenterControl.sol";
import "./InfoDB.sol";

contract UserModule{
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
