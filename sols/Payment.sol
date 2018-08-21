pragma solidity ^0.4.24;

import "./WhiteMange.sol";
import "./ERC20.sol";

/**
 * @title 提供一个授权以后，扣除用户代币的功能。
 * @author JustinQP 2018-07-17
 * @dev 为了能扣除用户的代币，需要对本合约授权，因为在第三方合约中，不能直接扣除token_代币。
 * @dev 本合约设计的目的，把授权扣款单独分离，保证此授权函数的安全和长期使用性。
 * @notice 因为用户将对此合约授权代币使用额度，因此需要一个风控函数，提供了暂停和终止支付的功能。
 */
contract Payment is WhiteMange{
    ERC20 public token_;
    bool public stopFlag_ = false;
    bool public pause_ = false;

    event LogStopPay(uint256 stopTime);
    event LogPausePay(bool status, uint256 changeTime);
    
    constructor(address _token, address _owner) public {
        owner = _owner;
        token_ = ERC20(_token);
    }

    /**
     * @dev 从本合约代扣一个地址的代币
     * @notice 请注意，需要用户先对本合约进行授权；只允许白名单中的名单调用权限。
     * @param _from The address to transfer from.
     * @param _to The address to transfer to.
     * @param _amount The amount to be transferred.
     */
    function payFrom(address _from, address _to, uint256 _amount) public returns(bool){
        // TODO:考虑增加一个bool,支持跳过第3,4步的验证。待定--Justin 0809
        if (stopFlag_ == true || pause_ == true) {
            emit LogError(RScorr.ServStop);
            return false;
        } /* 检查支付功能是否关闭 */

        if (whitelist_[msg.sender] != true) {
            emit LogError(RScorr.Insufficient);
            return false;
        } /* 检查是否具有白名单权限 */

        
        if (_amount > token_.allowance(_from, address(this))){
            emit LogError(RScorr.ScantCredit);
            return false;
        } /* 检查本代支付合约授权额度是否足够 */

        
        if (_amount > token_.balanceOf(_from)) {
            emit LogError(RScorr.ScantToken);
            return false;
        } /* 检查扣除代币的地址余额是否充足 */

        /* 扣除代币 */
        require(token_.transferFrom(_from, _to, _amount));
        return true;
    }


    ////////////////////
    ////Admin Function 
    ////////////////////

    /**
     * @dev 由管理员暂停本合约的代理消费的功能。
     * @param _stop     bool : 暂停支付功能的状态。
     * @return success _stop : 操作成功返回true。
     */
    function pause(bool _stop) public onlyAdmin returns(bool success){
        pause_ = _stop;
        emit LogPausePay(_stop, now);
        return true;
    }
    
    /**
     * @dev    由管理员owner终止本合约的代理消费的功能。出现不可逆风险时，终结此函数。
     * @return success bool : 操作成功返回true。
     */
    function terminate() public onlyOwner returns(bool success){
        require(stopFlag_ == false);

        stopFlag_ = true;
        emit LogStopPay(now);
        return true;
    }

    /**
     * @dev 判断地址能否通过本合约支付成功
     * @param _from  address : 支付地址
     * @param _value uint256 : 支付金额
     * @return bool 有支付能力返回true
     */
    function isPayable(address _from, uint256 _value)
        view
        public
        returns(bool)
    {
        if (_value > token_.allowance(_from, address(this))){
            return false;
        } /* 检查本代支付合约授权额度是否足够 */

        if (_value > token_.balanceOf(_from)) {
            return false;
        } /* 检查扣除代币的地址余额是否充足 */

        return true;
    }
}

