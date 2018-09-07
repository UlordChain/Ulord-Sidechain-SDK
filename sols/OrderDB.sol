pragma solidity ^0.4.24;

import "./WhiteMange.sol";


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



