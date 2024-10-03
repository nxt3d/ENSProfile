// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;
 
struct ExtensionData {
    bytes32 node;
    string key;
    address sender;
    address extensionResolver;
    bytes[] data;
    uint256 cycle;
}

interface IExtensionResolver {
    function resolveExtension(ExtensionData memory data) external returns (string memory);
}
