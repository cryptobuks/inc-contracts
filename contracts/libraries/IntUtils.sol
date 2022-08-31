// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * Integers Library
 * 
 * In summary this is a simple library of integer functions which allow a simple
 * conversion to and from strings
 */
library IntUtils {

    /**
     * @dev Converts an ASCII string value into an uint as long as the string 
     * its self is a valid unsigned integer
     * 
     * @param value The ASCII string to be converted to an unsigned integer
     * @return _ret uint The unsigned value of the ASCII string
     */
    function parseUInt(string memory value) internal pure returns (uint _ret) {
        bytes memory valueBytes = bytes(value);
        uint j = 1;
        for(uint t = valueBytes.length; t > 0; t--) {
            uint i = t - 1;
            assert(uint8(valueBytes[i]) >= 48 && uint8(valueBytes[i]) <= 57);
            _ret += (uint8(valueBytes[i]) - 48)*j;
            j*=10;
        }
    }

    /**
     * @dev Converts an ASCII string value into an int as long as the string 
     * its self is a valid signed integer
     * 
     * @param value The ASCII string to be converted to an signed integer
     * @return _ret int The signed value of the ASCII string
     */
    function parseInt(string memory value) internal pure returns (int _ret) {
        bytes memory valueBytes = bytes(value);
        if(valueBytes.length == 0) {
            return 0;
        }

        int j = 1;
        int sign = (uint8(valueBytes[0]) == 45)? int(-1): int(1);
        uint min = (uint8(valueBytes[0]) == 45 || uint8(valueBytes[0]) == 43)? 1: 0;

        for(uint t = valueBytes.length; t > min; t--) {
            uint i = t - 1;
            assert(uint8(valueBytes[i]) >= 48 && uint8(valueBytes[i]) <= 57);
            _ret += int8(uint8(valueBytes[i]) - 48)*int(j);
            j*=10;
        }

        _ret *= sign;
    }

    /**
     * @dev Converts an unsigned integer to the ASCII string equivalent value
     * 
     * @param value The unsigned integer to be converted to a string
     * @return string The resulting ASCII string value
     */
    function toString(uint value) internal pure returns (string memory) {
        bytes memory tmp = new bytes(32);
        uint i;
        for(i = 0; value > 0; i++) {
            tmp[i] = bytes1(uint8((value % 10) + 48));
            value /= 10;
        }
        bytes memory real = new bytes(i--);
        for(uint j = 0; j < real.length; j++) {
            real[j] = tmp[i--];
        }
        return string(real);
    }
}
