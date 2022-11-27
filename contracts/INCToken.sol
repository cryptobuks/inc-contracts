// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @dev An ERC20 token for INC. Managed by the government of the DAO ´owner´.
 * The following functionalities are added:
 * - Voting capabilities.
 * - Support for the owner (the DAO) to mint new tokens, at up to 10% PA.
 */
contract INCToken is ERC20, ERC20Permit, ERC20Votes, Ownable {

    uint256 public constant mintInterval = 365 days;
    uint256 public constant mintCapacity = 10; // 10%
    uint256 public nextMint; // Timestamp from which it can be mined again
    
    constructor(uint256 totalSupply) ERC20("Incentive", "INC") ERC20Permit("Incentive") {
        _mint(_msgSender(), totalSupply);
        nextMint = block.timestamp + mintInterval;
    }

    /**
     * @dev Mint new tokens.
     * It can only be executed each `mintInterval` by the owner (DAO Governance), 
     * and cannot exceed the `mintCapacity / 100` fraction of the current total supply.
     */
    function mint(address to, uint256 amount) external onlyOwner {
        require(amount <= (totalSupply() * mintCapacity) / 100, "INCToken: mint exceeds maximum amount");
        require(block.timestamp >= nextMint, "INCToken: cannot mint yet");

        nextMint = block.timestamp + mintInterval;
        _mint(to, amount);
    }

    // The following functions are overrides required by Solidity.

    function _afterTokenTransfer(address from, address to, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._afterTokenTransfer(from, to, amount);
    }

    function _mint(address to, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._mint(to, amount);
    }

    function _burn(address account, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._burn(account, amount);
    }
}