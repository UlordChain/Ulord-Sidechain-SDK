pragma solidity ^0.4.24;

import "./WhiteMange.sol";
import "./ClaimDB.sol";
import "./OrderDB.sol";

/**
 * @title 管理所有合约中特殊的权限，
 * @dev 只需要把Admin权限转过来，不要转Owner权限,因为owner能改变Admin
 * @dev 需要一个权限控制名单
 * 
 *  1. ClaimDB 的删除资源的权限
 *  2. ClaimDB 的屏蔽一个资源的权限 
 *  3. 暂停或恢复支付合约的支付功能的权限
 *  4. OrderDB 的删除订单的权限
 *  5. 修改资源押金数量的权限
 */
contract AdminModule is WhiteMange {
    ClaimDB public Claim_;
    OrderDB public Order_;
    //CenterPublish public Center;

    constructor (address _claimDb, address _orderDb, address _owner)
    public
    {
        owner = _owner;
        Claim_ = ClaimDB(_claimDb);
        Order_ = OrderDB(_orderDb);
    }

    /**
     * @dev    用于管理多个合约的白名单
     * @param  _contract address   : 操作的合约
     * @param  _target   address   : 控制的地址
     * @param  _allow    bool      : ture 代表开启
     * @return           bool      : 操作成功返回true
     */
    function mangeDestWhite(address _contract, address _target, bool _allow) onlyAdmin
    public
    returns (bool)
    {
        // 检测权限
        WhiteMange _destCon = WhiteMange(_contract);
        if (_destCon.admin() != address(this)) {
            emit LogError(RScorr.PermissionDenied);
            return false;
        }

        // "0xa8e1fba3": "mangeWhiteList(address,bool)"
        //return _contract.call(bytes4(0xa8e1fba3), _target, _allow); 这种调用方式只有这次调用动作的bool，不是执行
        return _destCon.mangeWhiteList(_target, _allow);
    }

    /****************** Claim  ********************/
    /**
     * @dev    删除资源
     * @param  _claimId  bytes16  : 资源ID
     * @return           bool     : 删除成功返回true
     */
    function deleteClaim(bytes16 _claimId) onlyAdmin
    public
    returns (bool)
    {
        return Claim_.deleteClaim(_claimId);
    }

    /**
     * @dev    屏蔽资源，待审核后，恢复或删除资源
     * @param _claimId bytes16  :  资源ID
     * @param _allow   bool     :  屏蔽资源设置为true
     * @return         bool     :  操作成功返回true
     */
    function forbindonClaim(bytes16 _claimId, bool _allow) onlyAdmin
    public
    returns (bool)
    {
        return Claim_.updateClaimForbidden(_claimId, _allow);
    }


    /**
     * @dev    变更ClaimDB合约地址
     * @param  _newClaimDB address  : 新的claimDB合约地址
     * @return             bool     :  操作成功返回true
     */
    function changeClaimDB(address _newClaimDB) onlyAdmin
    public
    returns (bool)
    {
        require(_newClaimDB != 0);
        Claim_ = ClaimDB(_newClaimDB);
        return true;
    }

    /****************** Order  ********************/

    /**
     * @dev    删除订单
     * @param  _orderId  bytes32  :  订单ID
     * @return           bool     :  操作成功返回true
     */
    function deleteOrder(bytes32 _orderId) onlyAdmin
    public
    returns (bool)
    {
        return Order_.remove(_orderId);
    }

    /**
     * @dev    变更OrderDB合约地址
     * @param  _newOrderDB address :  新的orderDB合约地址
     * @return             bool    :  操作成功返回true
     */
    function changeOrderDB(address _newOrderDB) onlyAdmin
    public
    returns (bool)
    {
        require(_newOrderDB != 0);
        Order_ = OrderDB(_newOrderDB);
        return true;
    }

    /****************** Info  ********************/

    // Null

    /****************** PayMent  ********************/
    /**
     * @dev    暂停或者恢复支付合约的支付功能
     * @param _pay       address :  支付合约Payment的合约地址
     * @param _stopState bool    :  true代表暂停支付功能，false代表恢复支付功能
     * @return           bool    :  操作成功返回true
     */
    function pausePay(address _pay, bool _stopState) onlyAdmin
    public
    returns (bool)
    {
        if (isAdmin(_pay)) {
            // "02329a29": "pause(bool)
            require(_pay.call(bytes4(0x02329a29), _stopState));
            return true;
        } else {
            emit LogError(RScorr.PermissionDenied);
            return false;
        }
    }

    /****************** center  ********************/
    /**
     * @dev 修改资源的押金
     * @param _center  address : centerPublish合约地址
     * @param _deposit uint256 : 新的押金数量
     * @return         bool    : 操作成功返回true
     */
    function setClaimDeposit(address _center, uint256 _deposit) onlyAdmin
    public
    returns (bool)
    {
        if (isAdmin(_center)) {
            // "f5bade66": "setDeposit(uint256)"
            require(_center.call(bytes4(0xf5bade66), _deposit));
            return true;
        } else {
            emit LogError(RScorr.PermissionDenied);
            return false;
        }
    }

    // 增加一个更换合约是转移admin权限的函数的函数。、

    WhiteMange internal Whtie_;
    /**
     * @dev 转移本合约的管理权限给新的管理员
     * @notice 只能由owner操作
     * @param _newAdmin address   : 新管理合约的地址
     * @param _contract address[] : 待迁移的管理权限的合约地址列表
     * @return          bool      ：迁移成功返回true
     */
    function migrate(address _newAdmin, address[] _contract) onlyOwner
    public
    returns (bool)
    {
        uint256 _len = _contract.length;
        for (uint256 i = 0; i < _len; i++) {
            Whtie_ = WhiteMange(_contract[i]);
            require(Whtie_.admin() == address(this), "Sorry, you entered an invalid contract address");
            Whtie_.transferAdminship(_newAdmin);
        }
        return true;
    }

    /**
     * @dev 用于检测目标合约地址的管理员是否为本合约
     * @param _contract address : 待验证的合约地址。
     * @return          bool    : 是管理员amdin则返回true
     */
    function isAdmin(address _contract) view public returns (bool){
        if (WhiteMange(_contract).admin() == address(this)) {
            return true;
        } else {
            return false;
        }

    }
}

