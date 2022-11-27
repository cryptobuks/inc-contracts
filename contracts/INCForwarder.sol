// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "./interfaces/IForwarder.sol";
import "./abstractions/Manageable.sol";

/**
 * @dev Forwarder to be used together with an ERC2771 compatible contract. See {Forwardable}.
 */
contract INCForwarder is IForwarder, Manageable, EIP712 {

    using ECDSA for bytes32;

    bytes32 private constant _TYPEHASH =
        keccak256("ForwardRequest(address from,address to,uint256 value,uint256 gas,uint256 nonce,bytes data)");

    mapping(address => uint256) private _nonces;
    mapping(address => bool) private _senderWhitelist;

    constructor() EIP712("INCForwarder", "0.0.1") {}

    /**
     * @dev See {IForwarder-DOMAIN_SEPARATOR}
     */
    function DOMAIN_SEPARATOR()
    external view override
    returns (bytes32) {
        return _domainSeparatorV4();
    }

    /**
     * @dev See {IForwarder-custody}
     */
    function custody()
    external view override
    returns(address) {
        return manager();
    }

    /**
     * @dev See {IForwarder-getNonce}
     */
    function getNonce(address from)
    external view override
    returns (uint256) {
        return _nonces[from];
    }

    /**
     * @dev See {IForwarder-verify}
     */
    function verify(ForwardRequest calldata req, bytes calldata signature)
    public view override
    returns (bool) {
        address signer = _hashTypedDataV4(
            keccak256(abi.encode(_TYPEHASH, req.from, req.to, req.value, req.gas, req.nonce, keccak256(req.data)))
        ).recover(signature);
        return _nonces[req.from] == req.nonce && signer == req.from;
    }

    /**
     * @dev See {IForwarder-execute}
     */
    function execute(ForwardRequest calldata req, bytes calldata signature)
    external payable override
    returns (bool, bytes memory) {
        require(_senderWhitelist[_msgSender()], "INCForwarder: sender of meta-transaction is not whitelisted");
        require(verify(req, signature), "INCForwarder: signature does not match request");
        _nonces[req.from] = req.nonce + 1;

        (bool success, bytes memory returndata) = (req.gas > 0)? 
        req.to.call{gas: req.gas, value: req.value}(abi.encodePacked(req.data, req.from)):
        req.to.call{value: req.value}(abi.encodePacked(req.data, req.from));

        if (!success) {
            assembly {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }

        /**
         * @dev Validates that the relayer/forwarder EOA has sent enough gas for the call.
         * See https://ronan.eth.link/blog/ethereum-gas-dangers/
         */
        assert(gasleft() > req.gas / 63);

        emit MetaTransactionExecuted(req.from, req.to, req.data);

        return (success, returndata);
    }

    /**
     * @dev See {IForwarder-isWhitelisted}
     */
    function isWhitelisted(address sender)
    external override view
    returns (bool) {
        return _senderWhitelist[sender];
    }

    /**
     * @dev See {IForwarder-addSenderToWhitelist}
     */
    function addSenderToWhitelist(address sender)
    external override onlyOwner {
        require(!_senderWhitelist[sender], "INCForwarder: sender address is already whitelisted");
        _senderWhitelist[sender] = true;
        emit AddressWhitelisted(sender);
    }

    /**
     * @dev See {IForwarder-removeSenderFromWhitelist}
     */
    function removeSenderFromWhitelist(address sender)
    external override onlyOwner {
        _senderWhitelist[sender] = false;
        emit AddressRemovedFromWhitelist(sender);
    }
}