
pragma solidity ^0.4.24;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./UshareToken.sol";

/**
 * @title 本合约用来锁定和释放开发团队的代币。
 * @dev   锁定数量： 代币总量的5%，共5亿
 * @dev   解锁规则： 每年解锁数量的1%（1亿枚） 
 * @dev   解锁操作： 由管理员调用，把代币释放到指定的地址（该地址不可变更）
 */
contract TeamToken is Ownable{
    using SafeMath for uint256;

    UshareToken public UX;
    uint256 public startTime;
    uint256 internal duration = 365 * 24 * 3600; //six months

    uint256 public total = 500000000000000000000000000;   // 500 million  5% 
    uint256 public amountPerRelease = total.div(5);       // 100 million
    uint256 public collectedTokens;

    address public TeamAddress;

    event TokensWithdrawn(address indexed _holder, uint256 _amount);

    /**
     * @dev TeamDevTokens 合约构造函数
     * @param _token address 已部署的Ushare代币合约地址
     * @param _team address 团队代币接受者
     */
    constructor(address _token, address _team, address _owner) public{
        require(_token != 0x0 && _team != 0x0);
        UX = UshareToken(_token);
        TeamAddress = _team;
        startTime = now;
        owner = _owner;
    }

    /*
     * @dev The Dev (Owner) will call this method to extract the tokens
     */
    function unLock() public onlyOwner returns(bool){
        uint256 unlockable = calculation();

        if (unlockable == 0){
            revert();
        } 

        assert (UX.transfer(TeamAddress, unlockable));
        emit TokensWithdrawn(TeamAddress, unlockable);
        collectedTokens = collectedTokens.add(unlockable);
        
        return true;
    }

    /**
     * @dev 获取当前时间可解锁的代币总量
     *      单次可取的数量需要减去已提取的数量
     * @return amount uint256 可解锁的代币总数量。
     */
    function calculation() view public returns(uint256 amount){
        uint256 balance = UX.balanceOf(this);

        //  amountPerRelease * [(now - startTime) / duration]
        uint256 canExtract = amountPerRelease.mul((getTime().sub(startTime)).div(duration));

        uint256 _amount = canExtract.sub(collectedTokens);

        if (_amount > balance) {
            _amount = balance;
        }

        return _amount;
    }

    /**
     * @dev Get the timestamp of the current block
     * @return timestamp uint256 : Latest block timestamp
     */
    function getTime() view public returns(uint256){
        return now;
    }
}
