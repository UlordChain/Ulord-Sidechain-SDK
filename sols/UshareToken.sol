pragma solidity ^0.4.24;

import "./StandardToken.sol";

/**
 * @title Ushare 代币合约的主体
 * @dev 部署说明
 * @dev 1. 先部署UshareToken
 * @dev 2. 再部署PoolTokens 和 TeamToken
 * @dev 3. 最后获取2个合约的地址后，再初始化代币分配
 */
contract UshareToken is StandardToken {
    string public constant name = "Ushare Token";
    string public constant symbol = "UX";
    uint8 public constant decimals = 18;

    address public RewardPool; //55%
    address public Operation; //25%
    address public Foundation; //15%
    address public TeamDev; //5%

    address public owner;

    constructor() public {
        totalSupply = 100 * 100000000 * (10 ** uint256(decimals));
        owner = msg.sender;
    }

    /**
     * @dev 初始化代币分配，只允许由管理员调用
     * @param _dev        address : TeamTokens 开发团队合约部署地址
     * @param _pool       address : PoolTokens 奖励池锁仓合约部署地址
     * @param _foundation address : 基金会地址
     * @param _operation  address : 运营地址
     */
    function initialize(address _dev, address _pool, address _foundation, address _operation) 
        public 
        returns(bool) 
    {
        require(msg.sender == owner);
        require (TeamDev == 0 && RewardPool == 0);
        require(_dev != 0 && _pool != 0 && _foundation != 0 && _operation != 0);
        
        TeamDev    = _dev;
        RewardPool = _pool;
        Foundation = _foundation;
        Operation  = _operation;

        balances[RewardPool] = totalSupply.mul(55).div(100);
        balances[Operation]  = totalSupply.mul(25).div(100);
        balances[Foundation] = totalSupply.mul(15).div(100);
        balances[TeamDev]    = totalSupply.mul(5).div(100);

        return true;
    }

    /**
     * @dev 提供一个查询奖励池剩余资金池的方法
     * @return balance uint256 : 奖励池的剩余代币数量
     */
    function Pool() view public returns(uint256 balance){
        return balances[RewardPool];
    }
}