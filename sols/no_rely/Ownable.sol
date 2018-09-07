pragma solidity ^0.4.24;
/**
 * @title OwnBase
 * @dev The OwnBase contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract OwnBase {
    address public owner;

    event LogOwnershipRenounced(address indexed previousOwner);
    event LogOwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );


    /**
     * @dev The OwnBase constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() public {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param _newOwner address : The address to transfer ownership to.
     */
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0));
        emit LogOwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     * @notice Renouncing to ownership will leave the contract without an owner.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     */
    function renounceOwnership() public onlyOwner {
        emit LogOwnershipRenounced(owner);
        owner = address(0);
    }
}


/**
 * @title Ownable
 * @dev Extension for the OwnBase contract, where the ownership needs to be confirmed.
 * This allows the new owner to accept the transfer.
 */
contract Ownable is OwnBase {
    address public newOwner;

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyNewOwner() {
        require(msg.sender == newOwner);
        _;
    }


    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param _newOwner The address to transfer ownership to.
     */
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0));
        newOwner = _newOwner;
    }

    /**
     * @dev Allows the newOwner address to finalize the transfer.
     */
    function acceptOwnership() public onlyNewOwner {
        emit LogOwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}


/**
 * @title 管理员扩展模块
 * @dev 避免单点故障，导致合约管理权限丢失，因此增加一个管理员
 *     推荐一般使用admin，owner作为根权限保存。
 *    owner的权限比admin要高。
 */
contract OwnPlus is Ownable {
    address public admin;

    event LogAdminshipTransferred(address indexed _old, address indexed _new);

    constructor () public {
        admin = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyAdmin() {
        require (msg.sender == owner || msg.sender == admin);
        _;
    }

    /**
     * @dev Allows the current admin to transfer control of the contract to a newadmin.
     * @param _newAdmin address : new admin address
     */
    function transferAdminship(address _newAdmin) onlyAdmin public {
        emit LogAdminshipTransferred(admin, _newAdmin);
        admin = _newAdmin;
    }
}
