pragma solidity ^0.4.24;

import "./WhiteMange.sol";


contract MulTransfer is WhiteMange{
    /**
     * @dev constructor
     * @param _owner  address : the contract owner
     */
    constructor (address _owner) public {
        owner = _owner;
        whitelist_[msg.sender] = true;
    }

    modifier onlyWhite{
        require(whitelist_[msg.sender] == true);
        _;
    }

    //////////////
    //// White
    //////////////

    // can accept ETH.
    function() payable public {

    }

    /**
     * @dev Transfer to multiple addresses to a different number of tokens.
     * @param _addresses addressp[] : recipient's address list
     * @param _value     uint256[]  : a list of the number corresponding to each address
     */
    function mulPayDiff(address[] _addresses, uint256[] _value) onlyWhite
        public
        payable
        returns(bool)
    {
        require(_addresses.length == _value.length);
        for(uint256 i = 0; i < _addresses.length; i++){
            _addresses[i].transfer(_value[i]);
        }
        return true;
    }

    /**
     * @dev Transfer the same token number to multiple addresses
     * @param _amount      uint256   : number of tokens
     * @param _addresses   uint256[] : recipient's address list
     */
    function mulPaySame(uint256 _amount, address[] _addresses) onlyWhite
        public
        payable
        returns(bool)
    {
        for(uint256 i = 0; i < _addresses.length; i++){
            _addresses[i].transfer(_amount);
        }
        return true;
    }

    function getBalance() view public returns(uint256){
        return address(this).balance;
    }
}



