pragma solidity ^0.4.24;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./UshareToken.sol";


/**
 * @title 本合约用来锁定和释放奖励池的代币。
 * @dev   锁定数量： 代币总量的55%，共55亿
 * @dev   解锁规则： 每年解锁剩余数量的10%， 例如第一年5.5%，第二年4.95%
 * @dev   解锁操作： 由管理员调用，把代币释放到指定的地址（该地址不可变更）
 */
contract PoolToken is Ownable{
    using SafeMath for uint256;

    UshareToken public UX;

    uint256 public startTime;
    uint256 public PERCENT = 10;
    uint256 public oneYear = 365 * 24 * 3600;

    uint256 public lastReleaseTime;
    uint256 public collectedTokens;

    address public PoolAddress;

    /**
     * @dev RewardPoolTokens 合约构造函数
     * @param _token address 已部署的Ushare代币合约地址
     * @param _pool address 解锁后的代币的接受地址
     */
    constructor(address _token, address _pool, address _owner) public {
        require(_token != 0x0 && _pool != 0x0);
        UX = UshareToken(_token);
        PoolAddress = _pool;
        startTime = now;
        owner = _owner;
    }


    /**
     * @dev 在满足解锁条件时，由管理员用来释放代币的函数。
     */
    function unLock() public onlyOwner returns(bool){
        require (canUnlock());
        
        uint256 balance = UX.balanceOf(this);

        uint256 unlockamount = balance.mul(PERCENT).div(100);
        assert(UX.transfer(PoolAddress, unlockamount));
        collectedTokens = collectedTokens.add(unlockamount);

        lastReleaseTime = getTime();
        return true;
    }
    
    /**
     * @dev 判断是否满足下一期的释放条件
     * @return 满足条件可以解锁返回 true
     */
    function canUnlock() view public returns (bool){
        return getTime().sub(lastReleaseTime) >= oneYear;
    }


    /**
     * @dev Get the timestamp of the current block
     * @return timestamp uint256 : Latest block timestamp
     */
    function getTime () view public returns(uint256 timestamp) {
        return now;
    }  
}