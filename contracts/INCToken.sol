// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./abstractions/TokenBase.sol";

/**
 * @dev An ERC20 token for INC. Managed by the government of the DAO ´owner´.
 * The following functionalities are added:
 * - Voting capabilities.
 * - Timeline to obtain the balance of contributors.
 * - Support for the owner (the DAO) to mint new tokens, at up to 10% PA.
 */
contract INCToken is TokenBase, Ownable {

    uint256 public constant mintInterval = 365 days;
    uint256 public constant mintCap = 10; // 10%
    uint256 public nextMint; // Timestamp from which it can be mined again
    
    constructor(uint256 totalSupply) TokenBase("Incentive", "INC") {
        _mint(_msgSender(), totalSupply);
        nextMint = block.timestamp + mintInterval;
    }

    /**
     * @dev Mint new tokens.
     * It can only be executed each `mintInterval` by the owner (DAO Governance), 
     * and cannot exceed the `mintCap / 100` fraction of the current total supply.
     */
    function mint(address to, uint256 amount) external onlyOwner {
        require(amount <= (totalSupply() * mintCap) / 100, "INCToken: mint exceeds maximum amount");
        require(block.timestamp >= nextMint, "INCToken: cannot mint yet");

        nextMint = block.timestamp + mintInterval;
        _mint(to, amount);
    }

    /**
     * @dev Set maximum of points/metrics that can be returned per request.
     */
    function setTimelineMaxPerRequest(uint256 _timelineMaxPerRequest) external onlyOwner {
        timelineMaxPerRequest = _timelineMaxPerRequest;
    }

    /**
     * @dev Set maximum of addresses that can be returned per request.
     */
    function setHolderMaxPerRequest(uint256 _holderMaxPerRequest) external onlyOwner {
        holderMaxPerRequest = _holderMaxPerRequest;
    }
}
