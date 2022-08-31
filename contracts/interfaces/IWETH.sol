// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @dev Interface for wrapped native currency.
 */
interface IWETH is IERC20 {
    function deposit() external payable;
    function withdraw(uint) external;
    event  Deposit(address indexed dst, uint wad);
    event  Withdrawal(address indexed src, uint wad);
}
