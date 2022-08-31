// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IForwarder.sol";

/**
 * @dev Contract to assign trusted forwarder with ERC2771 support
 */
abstract contract Forwardable is Ownable {

    IForwarder public forwarderCnt;

    event ForwardingTransferred(address indexed previousForwarder, address indexed newForwarder);

    /**
     * @dev Initializes the contract setting the deployer as the initial forwarder.
     */
    constructor(address forwarder) {
        require(forwarder != address(0), "Forwardable: invalid forwarder address");
        setTrustedForwarder(forwarder);
    }

    /**
     * @dev Return true if the forwarder is trusted by the recipient.
     */
    function isTrustedForwarder(address forwarder) public view virtual returns(bool) {
        return forwarder == address(forwarderCnt);
    }

    /**
     * @dev Only the owner can change the forwarder.
     */
    function setTrustedForwarder(address newForwarder) public virtual onlyOwner {
        address oldForwarder = address(forwarderCnt);
        forwarderCnt = IForwarder(newForwarder);
        emit ForwardingTransferred(oldForwarder, newForwarder);
    }

    /**
     * @dev Throws if called by any account other than the forwarder.
     */
    modifier onlyTrustedForwarder() {
        require(isTrustedForwarder(_msgSender()), "Forwardable: caller is not the forwarder");
        _;
    }

    /**
     * @dev Return the sender of this call.
     * If the call came through our trusted forwarder, return the original sender.
     * Otherwise, return `msg.sender`.
     * Should be used in the contract anywhere instead of msg.sender or _msgSender()
     */
    function _fwdSender() internal view virtual returns (address sender) {
        if (msg.data.length>=20 && isTrustedForwarder(_msgSender())) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return _msgSender();
        }
    }

    /**
     * @dev Return the data of this call.
     * If the call came through our trusted forwarder, return the original data.
     * Otherwise, return `msg.data`.
     * Should be used in the contract anywhere instead of msg.data or _msgData()
     */
    function _fwdData() internal view virtual returns (bytes calldata) {
        if (msg.data.length>=20 && isTrustedForwarder(_msgSender())) {
            return msg.data[:msg.data.length - 20];
        } else {
            return _msgData();
        }
    }
}
