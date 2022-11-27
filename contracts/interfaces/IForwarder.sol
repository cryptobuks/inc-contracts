// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IForwarder {

    struct ForwardRequest {
        address from;
        address to;
        uint256 value;
        uint256 gas;
        uint256 nonce;
        bytes data;
    }

    event MetaTransactionExecuted(address indexed from, address indexed to, bytes indexed data);
    event AddressWhitelisted(address indexed sender);
    event AddressRemovedFromWhitelist(address indexed sender);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for `execute`, as defined by {EIP712}.
     * See https://eips.ethereum.org/EIPS/eip-712
     */
    function DOMAIN_SEPARATOR()
    external view
    returns (bytes32);

    /**
     * @dev Returns the custody address of the gas reserve.
     */
    function custody()
    external view
    returns (address);

    /**
     * @dev Retrieves the on-chain tracked nonce of an EOA making the request.
     */
    function getNonce(address from)
    external view
    returns(uint256);

    /**
     * @dev Verify the transaction would execute.
     * Validate the signature and the nonce of the request.
     * Revert if either signature or nonce are incorrect.
     */
    function verify(
        ForwardRequest calldata forwardRequest,
        bytes calldata signature
    ) 
    external view 
    returns (bool);

    /**
     * @dev Execute a transaction
     * The transaction is verified, and then executed.
     * The `success` and `returndata` of `call` are returned.
     * This method would revert only verification errors, target errors 
     * are reported using the returned data.
     */
    function execute(
        ForwardRequest calldata forwardRequest,
        bytes calldata signature
    )
    external payable 
    returns (bool, bytes memory);

    /**
     * @dev Retrieves the information whether an address is whitelisted or not.
     */
    function isWhitelisted(address sender)
    external view
    returns (bool);

    /**
     * @dev Only whitelisted addresses are allowed to broadcast meta-transactions.
     */
    function addSenderToWhitelist(address sender)
    external;

    /**
     * @dev Removes a whitelisted address.
     */
    function removeSenderFromWhitelist(address sender)
    external;
}