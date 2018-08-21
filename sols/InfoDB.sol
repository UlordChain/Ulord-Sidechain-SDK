pragma solidity ^0.4.24;

import "./WhiteMange.sol";

/**
 * @title 用于查询
 * @dev 数据写入需要白名单权限
 */
contract InfoDB is WhiteMange{

    // list最多存多少, 循环最多一次uint8=256
    // list本身没限制，查询也没限制
    // list分批查询问题，先不管这个问题
    // TODO:当一个列表比较大的时候，怎么有效的查询（>10000）

    struct stUserInfo{
        //uint256 orderCnt;
        bytes32[] orderList;   // 购买订单
        bytes16[] goodsList;   // 购买过的资源
    }

    struct stAuthorInfo{
        bytes16[] claims;       //作者发布过的资源
    }

    struct stClaimInfo{
        mapping(address => bytes32) bought; // 查询一个用户在这个资源下的订单
        address[] buyers;                   // 已购买的用户地址
        bytes32[] orderList;                // 买该资源的订单
    }

    mapping(address => stUserInfo) user_;
    mapping(bytes16 => stClaimInfo) claim_;
    mapping(address => stAuthorInfo) author_;

    constructor (address _owner) public {
        owner = _owner;
    }

    /**
     * @dev 记录一笔订单
     * @param _oId   bytes32  : 订单ID
     * @param _cid   bytes16  : 资源ID
     * @param _buyer address  : 购买者地址
     * @return       bool     : 操作成功返回true
     */
    function insertOrder(bytes32 _oId, bytes16 _cid, address _buyer)
        public
        returns(bool)
    {
        if (whitelist_[msg.sender] != true){
            emit LogError(RScorr.Insufficient);
            return false;
        } /* Check the caller for white list permissions */

        user_[_buyer].orderList.push(_oId);
        user_[_buyer].goodsList.push(_cid);
        // 记录资源的购买者
        claim_[_cid].buyers.push(_buyer);
        // 建立购买索引
        claim_[_cid].bought[_buyer] = _oId;

        return true;
    }

    /**
     * @dev 记录一个资源产生
     * @param _cid    bytes16  : 资源ID
     * @param _author address  : 作者地址
     * @return        bool     : 操作成功返回true
     */
    function insertClaim(bytes16 _cid, address _author)
        public
        returns(bool)
    {
        if (whitelist_[msg.sender] != true){
            emit LogError(RScorr.Insufficient);
            return false;
        } /* Check the caller for white list permissions */

        author_[_author].claims.push(_cid);
        return true;
    }

    /////////////////////////
    /// View
    /////////////////////////

    /**
     * @dev 查询作者已发布过的所有资源
     * @param _author  address   : 作者地址
     * @return         bytes16[] : claimID组成的bytes16的列表
     */
    function getClaimsByAuthor(address _author) view public returns(bytes16[]){
        return author_[_author].claims;
    }

    /**
     * @dev 查询用户已购买的所有资源
     * @param _user    address   : 作者地址
     * @return         bytes16[] : claimID组成的bytes16的列表
     */
    function getClaimsByUser(address _user) view public returns(bytes16[]){
        return user_[_user].goodsList;
    }

    /**
     * @dev 查询用户的所有的订单
     * @param _buyer   address   : 用户地址
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
     * @dev 查询制定用户是否购买了资源
     * @param _buyer address : 用户地址
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
