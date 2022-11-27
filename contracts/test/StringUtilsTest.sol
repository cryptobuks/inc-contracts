// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import '../libraries/StringUtils.sol';

contract StringUtilsTest {

    function toSlice(string memory self) external pure returns (StringUtils.slice memory) {
        return StringUtils.toSlice(self);
    }

    function len(bytes32 self) external pure returns (uint) {
        return StringUtils.len(self);
    }

    function toSliceB32(bytes32 self) external pure returns (StringUtils.slice memory ret) {
        return StringUtils.toSliceB32(self);
    }

    function copy(StringUtils.slice memory self) external pure returns (StringUtils.slice memory) {
        return StringUtils.copy(self);
    }

    function toString(StringUtils.slice memory self) external pure returns (string memory) {
        return StringUtils.toString(self);
    }

    function len(StringUtils.slice memory self) external pure returns (uint l) {
        return StringUtils.len(self);
    }

    function empty(StringUtils.slice memory self) external pure returns (bool) {
        return StringUtils.empty(self);
    }

    function compare(StringUtils.slice memory self, StringUtils.slice memory other) external pure returns (int) {
        return StringUtils.compare(self, other);
    }

    function equals(StringUtils.slice memory self, StringUtils.slice memory other) external pure returns (bool) {
        return StringUtils.equals(self, other);
    }

    function nextRune(StringUtils.slice memory self, StringUtils.slice memory rune) external pure returns (StringUtils.slice memory) {
        return StringUtils.nextRune(self, rune);
    }

    function nextRune(StringUtils.slice memory self) external pure returns (StringUtils.slice memory ret) {
        return StringUtils.nextRune(self);
    }

    function ord(StringUtils.slice memory self) external pure returns (uint ret) {
        return StringUtils.ord(self);
    }

    function keccak(StringUtils.slice memory self) external pure returns (bytes32 ret) {
        return StringUtils.keccak(self);
    }

    function startsWith(StringUtils.slice memory self, StringUtils.slice memory needle) external pure returns (bool) {
        return StringUtils.startsWith(self, needle);
    }

    function beyond(StringUtils.slice memory self, StringUtils.slice memory needle) external pure returns (StringUtils.slice memory) {
        return StringUtils.beyond(self, needle);
    }

    function endsWith(StringUtils.slice memory self, StringUtils.slice memory needle) external pure returns (bool) {
        return StringUtils.endsWith(self, needle);
    }

    function until(StringUtils.slice memory self, StringUtils.slice memory needle) external pure returns (StringUtils.slice memory) {
        return StringUtils.until(self, needle);
    }

    function find(StringUtils.slice memory self, StringUtils.slice memory needle) external pure returns (StringUtils.slice memory) {
        return StringUtils.find(self, needle);
    }

    function rfind(StringUtils.slice memory self, StringUtils.slice memory needle) external pure returns (StringUtils.slice memory) {
        return StringUtils.rfind(self, needle);
    }

    function split(StringUtils.slice memory self, StringUtils.slice memory needle, StringUtils.slice memory token) external pure returns (StringUtils.slice memory) {
        return StringUtils.split(self, needle, token);
    }

    function split(StringUtils.slice memory self, StringUtils.slice memory needle) external pure returns (StringUtils.slice memory token) {
        return StringUtils.split(self, needle);
    }

    function rsplit(StringUtils.slice memory self, StringUtils.slice memory needle, StringUtils.slice memory token) external pure returns (StringUtils.slice memory) {
        return StringUtils.rsplit(self, needle, token);
    }

    function rsplit(StringUtils.slice memory self, StringUtils.slice memory needle) external pure returns (StringUtils.slice memory token) {
        return StringUtils.rsplit(self, needle);
    }

    function count(StringUtils.slice memory self, StringUtils.slice memory needle) external pure returns (uint cnt) {
        return StringUtils.count(self, needle);
    }

    function contains(StringUtils.slice memory self, StringUtils.slice memory needle) external pure returns (bool) {
        return StringUtils.contains(self, needle);
    }

    function concat(StringUtils.slice memory self, StringUtils.slice memory other) external pure returns (string memory) {
        return StringUtils.concat(self, other);
    }

    function join(StringUtils.slice memory self, StringUtils.slice[] memory parts) external pure returns (string memory) {
        return StringUtils.join(self, parts);
    }

    function split(string memory str, string memory delim) external pure returns (string[] memory) {
        return StringUtils.split(str, delim);
    }

    function upper(string memory str) external pure returns (string memory) {
        return StringUtils.upper(str);
    }

    function lower(string memory str) external pure returns (string memory) {
        return StringUtils.lower(str);
    }

    function equalsIgnoreCase(string memory str, string memory other) external pure returns (bool) {
        return StringUtils.equalsIgnoreCase(str, other);
    }

    function containsIgnoreCase(string memory str, string memory other) external pure returns (bool) {
        return StringUtils.containsIgnoreCase(str, other);
    }

    function containsDigits(string memory str) external pure returns (bool) {
        return StringUtils.containsDigits(str);
    }

    function isDigit(string memory str) external pure returns (bool) {
        return StringUtils.isDigit(str);
    }

    function isUDigit(string memory str) external pure returns (bool) {
        return StringUtils.isUDigit(str);
    }

    function utfLength(string memory str) external pure returns (uint _length) {
        return StringUtils.utfLength(str);
    }

    function toHexString(uint256 value, uint256 length) external pure returns (string memory) {
        return StringUtils.toHexString(value, length);
    }

    function substring(string memory str, uint startIndex, uint endIndex) external pure returns (string memory) {
        return StringUtils.substring(str, startIndex, endIndex);
    }

    function ltrim(string memory _in) external pure returns (string memory) {
        return StringUtils.ltrim(_in);
    }

    function rtrim(string memory _in) external pure returns (string memory) {
        return StringUtils.rtrim(_in);
    }

    function trim(string memory _in) external pure returns (string memory) {
        return StringUtils.trim(_in);
    }
}