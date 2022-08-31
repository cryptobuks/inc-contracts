// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

/**
 * @dev Interface to keep track of holders.
 */
interface IHolding {

    /**
     * @dev Returns the maximum per holders request.
     */
    function holderMaxPerRequest() external view returns (uint256);

    /**
     * @dev Returns the position of the indicated holder
     */
    function holderPosition(address account) external view returns (uint256);

    /**
     * @dev Return number of holders
     */
    function holdersLength() external view returns (uint256);

    /**
     * @dev Returns `length` direcciones holders from the position indicated `cursor`
     */
    function holders(uint256 cursor, uint256 length) external view returns (address[] memory);
}
