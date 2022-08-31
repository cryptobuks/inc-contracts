// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ERC20Test is ERC20 {
    
    constructor(string memory name, string memory symbol, uint256 amount) 
        ERC20(name, symbol) {
        _mint(_msgSender(), amount);
    }

    function _msgSender() internal override view returns (address sender) {
        if (msg.data.length>=20) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return msg.sender;
        }
    }
}
