pragma solidity ^0.4.24;

import "./CenterControl.sol";
import "./ErrorModule.sol";
import "./InfoDB.sol";
import "./SafeMath.sol";

contract AuthorModule is ErrorModule{
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
     * @dev 声明一个新的资源
     * @dev 扣取押金到资源池，调用中心出版社接口，发布资源。
     * @param _udfs      string  : 资源的UDFS Hash值
     * @param _price     uint256 : 资源的定价，0表示免费
     * @param _type      uint8   : 资源的类型
     * @return           bool    : 操作成功返回 true
     */
    function publish(string _udfs, uint256 _price, uint8 _type)
        public
        payable
        returns(bool)
    {
        if(_hashFilter(_udfs) == false){
            emit LogError(RScorr.InvalidUdfs);
            return false;
        }

        //uint256 _value = msg.value;
        uint256 _deposit = getClaimDeposit();

        if (_deposit != 0){
            if(msg.value < _deposit){
                emit LogError(RScorr.Insolvent);
                return false;
            }
        }

        //向中心出版社发布一个资源， 这种方式是由平台层发布资源。
        //return Center_.createClaim(_udfs, msg.sender, _price, _type, true);
        if (Center_.createClaim(_udfs, msg.sender, _price, _type, true)){
            if (_deposit != 0){
                address(Center_).transfer(_deposit);           // 收押金
                msg.sender.transfer(msg.value.sub(_deposit)); // 退回多余的GAS
            }
            return true;
        }else{
            return false;
        }
    }


    function renewAD(bytes16 _claimId) payable public returns(bool){
        if (Center_.renewAD(_claimId, msg.value)){
            address(Center_).transfer(msg.value);
        }else{
            msg.sender.transfer(msg.value);
        }
    }

    /**
     * @dev 更新一个属于自己的资源的内容和价格
     * @param _claimId  bytes16 : 资源的索引
     * @param _newUdfs  string  : 新的udfs
     * @param _newPrice uint256 : 新的价格
     * @return          bool    : 操作成功返回 true
     */
    function updateClaim(bytes16 _claimId, string _newUdfs, uint256 _newPrice) public returns(bool){
        if(_hashFilter(_newUdfs) == false){
            emit LogError(RScorr.InvalidUdfs);
            return false;
        }

        return Center_.updateClaim(_claimId, msg.sender,  _newUdfs, _newPrice);
    }

    /**
     * @dev 放弃一个属于自己的资源
     * @param _claimId bytes16 : 资源的索引
     * @return         bool    : 操作成功返回 true
     */
    function abandonClaim(bytes16 _claimId) public returns(bool){
        return Center_.updateClaimWaive(_claimId, msg.sender, true);
    } //TODO : 放弃的资源，处理问题，如果作者想要重新发布。。会提示资源存在？How?

    /**
     * @dev 更新价格。
     * @param _claimId   bytes16 : 资源的索引
     * @param _newPrice  uint256 : 新的价格
     * @return           bool    : 操作成功返回 true
     */
    function updateClaimPrice(bytes16 _claimId, uint256 _newPrice) public returns(bool){
        return Center_.updateClaimPrice(_claimId, msg.sender, _newPrice);
    }

    /**
     * @dev 转让属于自己的资源。
     * @param _claimId    bytes16 : 资源的索引
     * @param _newAuthor  address : 新作者
     * @return            bool    : 操作成功返回 true
     */
    function transferClaim(bytes16 _claimId, address _newAuthor) public returns(bool){
        return Center_.updateClaimAuthor(_claimId, msg.sender, _newAuthor);
    } //TODO:能交易已放弃的资源，得改

    /////////////////////////
    /// View
    /////////////////////////


    function getClaimDeposit() view public returns(uint256){
        return Center_.claimDeposit_();
    }

    /**
     * @dev 查询调用者发布过的所有资源
     * @return bytes16[] :由claimId组成的列表
     */
    function myClaims()
        view public returns(bytes16[])
    {
        return claimsByAddress(msg.sender);
    }

    /**
     * @dev 查询指定地址发布过的所有资源
     * @return  bytes16[] :由claimId组成的列表
     */
    function claimsByAddress(address _author)
        view public returns(bytes16[])
    {
        return Info_.getClaimsByAuthor(_author);
    }

    /**
     * @dev 查询资源的所有购买者地址
     * @return address[] :由购买者地址组成的列表
     */
    function consumerByClaim(bytes16 _claimId)
        view public returns(address[])
    {
        return Info_.getConsumerByClaim(_claimId);
    }

    /**
     * @dev 查询一个资源的详细信息
     * @param _claimID   bytes16 : 资源id
     * @return                   : 指定资源的详细信息
     *           author  address : 归属者
     *             udfs  string  : UDFS值
     *         initDate  uint256 : 发布时间
     *          deposit  uint256 : 押金
     *            price  uint256 : 定价
     *            waive  bool    : 作者是否放弃
     *            types  uint8   : 类型
     */
    function findClaimInfo(bytes16 _claimID) public view returns(
        address author, string  udfs, uint256 initDate, uint256 deposit,
        uint256 price, bool    waive, uint8   types)
    {
        return Center_.getClaimDetails(_claimID);
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


    ///////////////////////
    /// Internal Function  
    //////////////////////
    
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