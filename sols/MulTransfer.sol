pragma solidity ^0.4.24;

import "./ERC20.sol";
import "./WhiteMange.sol";


contract MulTransfer is WhiteMange{
    ERC20 public ERC20Token;

    /**
     * @dev constructor
     * @param _token  address : ERC20 contract deployment address
     * @param _owner  address : the contract owner
     */
    constructor (address _token, address _owner) public {
        owner = _owner;
        ERC20Token = ERC20(_token);
        whitelist_[msg.sender] = true;
    }

    modifier onlyWhite{
        require(whitelist_[msg.sender] == true);
        _;
    }

    //////////////
    //// White
    //////////////

    /**
     * @dev Transfer to multiple addresses to a different number of tokens.
     * @param _addresses addressp[] : recipient's address list
     * @param _value     uint256[]  : a list of the number corresponding to each address
     */
    function mulPayDiff(address[] _addresses, uint256[] _value) public onlyWhite returns(bool){
        require(_addresses.length == _value.length);
        for(uint256 i = 0; i < _addresses.length; i++){
            ERC20Token.transfer(_addresses[i], _value[i]);
        }
        return true;
    }

    /**
     * @dev Transfer the same token number to multiple addresses
     * @param _amount      uint256   : number of tokens
     * @param _addresses   uint256[] : recipient's address list
     */
    function mulPaySame(uint256 _amount, address[] _addresses) public onlyWhite returns(bool){
        for(uint256 i = 0; i < _addresses.length; i++){
            ERC20Token.transfer(_addresses[i], _amount);
        }
        return true;
    }

    /**
     * @dev Send the specified tokens through ContractAddress
     * @param _token address       : ERC20 contract address
     * @param _addresses address[] : recipient's address list
     * @param _value uint256[]     : a list of the number corresponding to each address
     */
    function mulTokenPay(address _token, address[] _addresses, uint256[] _value)
        public
        onlyWhite
        returns(bool)
    {
        require(_addresses.length == _value.length);
        ERC20 erc20Token_ = ERC20(_token);

        for(uint256 i = 0; i < _addresses.length; i++){
            erc20Token_.transfer(_addresses[i], _value[i]);
        }
        return true;
    }
    
    //////////////
    //// View
    //////////////

    /**
     * @dev Check the token balance of this contract
     * @return balance
     */
    function tokenAmount() public view returns(uint256){
        return ERC20Token.balanceOf(address(this));
    }
    
}