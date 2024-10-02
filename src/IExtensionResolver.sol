// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;
 
struct ExtensionData {
    bytes32 node;
    string key;
    address extensionResolver;
    bytes[] data;
    uint256 cycle;
}

interface IExtensionResolver {
    function resolveExtension(ExtensionData memory data) external returns (string memory);
    function extensionCallback(bytes[] calldata values, uint8, bytes calldata extraData) external returns (string memory);
}
