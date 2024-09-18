// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "openzeppelin/contracts/utils/introspection/ERC165.sol";
import "openzeppelin/contracts/access/AccessControl.sol";
import "./StringUtilsHook.sol";  // Import the utility library

// Import ENS interfaces
import "ens-contracts/resolvers/profiles/ITextResolver.sol";
import "ens-contracts/resolvers/profiles/IExtendedResolver.sol";

// Import forge-std console logging
import "forge-std/Console.sol";

contract FollowHook is ERC165, AccessControl, ITextResolver, IExtendedResolver {
    using StringUtilsHook for string;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
    }

    function supportsInterface(bytes4 interfaceID) public view override(ERC165, AccessControl) returns (bool) {
        return
            interfaceID == type(ITextResolver).interfaceId ||
            interfaceID == type(IExtendedResolver).interfaceId ||
            super.supportsInterface(interfaceID);
    }

    // Requests allow for a verifier to build a proof of the follows using the request stored in the "follow" key
    /// @custom:storage-location erc7201:ens.resolver.hooks
    struct HookStorage {
        mapping(string key => bytes) requests;
        bytes[] follows;
    }

    // This storage slot was calculated using EIP-7201, with the following formula:
    // bytes32(uint256(keccak256(abi.encode(uint256(keccak256("ens.resolver.hooks")) - 1))) & ~uint256(0xff))
    bytes32 private constant HOOK_STORAGE_LOCATION =
        0x183a6125c38840424c4a85fa12bab2ab606c4b6d0e7cc73c0c06ba5300eab500;

    function _hookStorage() private pure returns (HookStorage storage hs) {
        bytes32 position = HOOK_STORAGE_LOCATION;
        assembly {
            hs.slot := position
        }
    }

    event RequestSet(string indexed key, bytes indexed request);

    // a function that sets a request
    function setRequest(string memory key, bytes memory _request) external onlyRole(ADMIN_ROLE){
        HookStorage storage hs = _hookStorage();
        hs.requests[key] = _request;
        emit RequestSet(key, _request);
    }

    function getRequest(string memory key) external view returns (bytes memory) {
        HookStorage storage hs = _hookStorage();
        return hs.requests[key];
    }

    event FollowRecordAdded(bytes indexed followRecord);
    event FollowRecordRemoved(bytes indexed followRecord);

    function addFollow(bytes calldata followRecord) external onlyRole(ADMIN_ROLE) {
        HookStorage storage hs = _hookStorage();
        hs.follows.push(followRecord);
        emit FollowRecordAdded(followRecord);
    }

    function addFollowBatch(bytes[] calldata followRecords) external onlyRole(ADMIN_ROLE) {
        HookStorage storage hs = _hookStorage();
        for (uint256 i = 0; i < followRecords.length; i++) {
            hs.follows.push(followRecords[i]);
            emit FollowRecordAdded(followRecords[i]);
        }
    }

    // add a function that adds bytes to the request data to the 

    function removeFollowByIndex(uint256 index) external onlyRole(ADMIN_ROLE) {
        HookStorage storage hs = _hookStorage();
        uint256 length = hs.follows.length;

        require(index < length, "Index out of bounds");

        emit FollowRecordRemoved(hs.follows[index]);
        hs.follows[index] = hs.follows[length - 1];
        hs.follows.pop();
    }

    function getFollowByIndex(uint256 index) external view returns (bytes memory) {
        HookStorage storage hs = _hookStorage();
        require(index < hs.follows.length, "Index out of bounds");
        return hs.follows[index];
    }

    function totalFollows() external view returns (uint256) {
        HookStorage storage hs = _hookStorage();
        return hs.follows.length;
    }

    function text(bytes32, string calldata key) external view override returns (string memory) {
        HookStorage storage hs = _hookStorage();

        if (key.startsWith("hook:follow:")) {
            (uint256 start, uint256 end, address hookAddress) = _parseFollowKey(key);

            require(hookAddress == address(this), "Invalid hook address");

            require(end < hs.follows.length, "End index out of bounds");
            require((end - start + 1) <= 21, "Max length of follows list is 21");

            bytes[] memory followsList = new bytes[](end - start + 1);
            for (uint256 i = start; i <= end; i++) {
                followsList[i - start] = hs.follows[i];
            }

            return _encodeFollows(followsList);
        }

        return "";
    }

    function resolve(bytes calldata, bytes calldata data) external view override returns (bytes memory) {
        bytes4 selector = bytes4(data[:4]);

        if (selector == ITextResolver.text.selector) {
            (bytes32 node, string memory key) = abi.decode(data[4:], (bytes32, string));
            string memory result = this.text(node, key);
            return abi.encode(result);
        } else {
            revert("Unsupported function selector");
        }
    }

    function _parseFollowKey(string memory key) private pure returns (uint256, uint256, address) {
        string[] memory parts = key.split(":");

        require(parts.length == 4, "Invalid key format");

        string[] memory indices = parts[2].split(",");
        require(indices.length == 2, "Invalid indices format");

        uint256 start = indices[0].parseUint();
        uint256 end = indices[1].parseUint();

        address hookAddress = parts[3].parseAddress();

        return (start, end, hookAddress);
    }

    function _encodeFollows(bytes[] memory followsList) private pure returns (string memory) {
        string memory result = "[";

        for (uint256 i = 0; i < followsList.length; i++) {
            result = string(abi.encodePacked(result, followsList[i]));
            if (i < followsList.length - 1) {
                result = string(abi.encodePacked(result, ","));
            }
        }

        return string(abi.encodePacked(result, "]"));
    }
}
