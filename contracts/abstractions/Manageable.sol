// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @dev Contract to assign access to specific functions to the management contract.
 */
abstract contract Manageable is Ownable {

    address private _manager;
    event ManagementTransferred(address indexed previousManager, address indexed newManager);

    /**
     * @dev Initializes the contract setting the deployer as the initial manager.
     */
    constructor() {
        setManager(_msgSender());
    }

    /**
     * @dev Returns the address of the current manager.
     */
    function manager() public view virtual returns (address) {
        return _manager;
    }

    /**
     * @dev Only the owner can change the manager.
     */
    function setManager(address newManager) public virtual onlyOwner {
        address oldManager = _manager;
        _manager = newManager;
        emit ManagementTransferred(oldManager, newManager);
    }

    /**
     * @dev Throws if called by any account other than the manager.
     */
    modifier onlyManager() {
        require(manager() == _msgSender(), "Manageable: caller is not the manager");
        _;
    }
}
