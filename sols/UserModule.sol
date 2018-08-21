pragma solidity ^0.4.24;

import "./StrFilter.sol";
import "./CenterPublish.sol";
import "./InfoDB.sol";

contract UserModule{
    //using StrFilter for string;

    CenterPublish public Center_;
    InfoDB public Info_;

    /**
     * @dev 构造函数
     * @param _center address : 中心合约地址
     * @param _info   address : 信息数据合约地址
     */
    constructor (address _center, address _info) public {
        Center_ = CenterPublish(_center);
        Info_   = InfoDB(_info);
    }


    /**
     * @dev 购买资源
     * @param _claimId bytes16 : 资源id
     * @return         bool    : 操作成功返回true
     */
    function buy(bytes16 _claimId) public returns(bool){
        // 先获取资源的信息
        return Center_.createOrder(msg.sender, _claimId, msg.sender, 0);
    }

    /**
     * @dev 购买资源赠送给指定地址
     * @param _claimId bytes16 : 资源id
     * @param _donee   address : 受赠地址
     * @return         bool    : 操作成功返回true
     */
    function buyTo(bytes16 _claimId, address _donee) public returns(bool){
        return Center_.createOrder(_donee, _claimId, msg.sender, 0);
    }



//    /**
//     * @dev 使用其他地址购买
//     * @dev 付款人需要有足够的授权额度
//     * @param _claimId bytes16 : 资源id
//     * @param _payer   address : 付款地址
//     */
//    function buyFrom(bytes16 _claimId, address _payer) public returns(bool){
//        Center_.createOrder(msg.sender, _claimId, _payer, 0);
//        return true;
//    }
//    扣除不了授权额度。实现困难。。
////////////////////////////////

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
