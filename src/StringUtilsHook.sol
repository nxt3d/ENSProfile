// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Console.sol";

library StringUtilsHook {
    
    function parseUint(string memory str) internal pure returns (uint256) {
        bytes memory bstr = bytes(str);
        uint256 result = 0;
        for (uint256 i = 0; i < bstr.length; i++) {
            // Ensure that the character is a valid number
            require(bstr[i] >= 0x30 && bstr[i] <= 0x39, "Invalid character in string");
            result = result * 10 + (uint256(uint8(bstr[i])) - 48); // ASCII '0' is 48
        }
        return result;
    }

    function parseAddress(string memory str) internal pure returns (address) {
        bytes memory b = bytes(str);
        require(b.length == 40, "Invalid address length");

        uint160 result = 0;
        for (uint256 i = 0; i < 40; i++) {
            uint160 value = uint160(uint8(b[i]));

            if (value >= 48 && value <= 57) {
                result = result * 16 + (value - 48); // 0-9 -> 0x30-0x39
            } else if (value >= 97 && value <= 102) {
                result = result * 16 + (value - 87); // a-f -> 0x61-0x66
            } else if (value >= 65 && value <= 70) {
                result = result * 16 + (value - 55); // A-F -> 0x41-0x46
            } else {
                revert("Invalid character in address string");
            }
        }
        return address(result);
    }

    function startsWith(string memory str, string memory prefix) internal pure returns (bool) {
        return bytes(str).length >= bytes(prefix).length && keccak256(abi.encodePacked(substring(str, 0, bytes(prefix).length))) == keccak256(abi.encodePacked(prefix));
    }

    function substring(string memory str, uint256 startIndex, uint256 endIndex) internal pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(endIndex - startIndex);
        for (uint256 i = startIndex; i < endIndex; i++) {
            result[i - startIndex] = strBytes[i];
        }
        return string(result);
    }

    function split(string memory str, string memory delimiter) internal pure returns (string[] memory) {
        bytes memory strBytes = bytes(str);
        bytes memory delimiterBytes = bytes(delimiter);
        uint256 count = 1;
        for (uint256 i = 0; i < strBytes.length - delimiterBytes.length + 1; i++) {
            if (compareSubstring(strBytes, delimiterBytes, i)) {
                count++;
            }
        }

        string[] memory parts = new string[](count);
        uint256 lastIndex = 0;
        uint256 partIndex = 0;
        for (uint256 i = 0; i < strBytes.length - delimiterBytes.length + 1; i++) {
            if (compareSubstring(strBytes, delimiterBytes, i)) {
                parts[partIndex++] = substring(str, lastIndex, i);
                lastIndex = i + delimiterBytes.length;
            }
        }
        parts[partIndex] = substring(str, lastIndex, strBytes.length);
        return parts;
    }

    function compareSubstring(bytes memory strBytes, bytes memory delimiterBytes, uint256 index) internal pure returns (bool) {
        for (uint256 i = 0; i < delimiterBytes.length; i++) {
            if (strBytes[i + index] != delimiterBytes[i]) {
                return false;
            }
        }
        return true;
    }

    function concat(string memory a, string memory b) internal pure returns (string memory) {
        return string(abi.encodePacked(a, b));
    }

    function addressToString(address _address) internal pure returns (string memory) {
        bytes32 value = bytes32(uint256(uint160(_address)));
        bytes memory alphabet = "0123456789abcdef";
        bytes memory str = new bytes(40);

        for (uint256 i = 0; i < 20; i++) {
            str[i * 2] = alphabet[uint8(value[i + 12] >> 4)];
            str[i * 2 + 1] = alphabet[uint8(value[i + 12] & 0x0f)];
        }
        return string(str);
    }

}
