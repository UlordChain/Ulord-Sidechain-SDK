pragma solidity ^0.4.24;

import "./WhiteMange.sol";

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
