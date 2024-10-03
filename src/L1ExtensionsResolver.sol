// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;
 
import  "@unruggable/contracts/GatewayProtocol.sol";
import {GatewayFetcher, GatewayRequest} from "@unruggable/contracts/GatewayFetcher.sol";
import {GatewayFetchTarget, IGatewayProofVerifier} from "@unruggable/contracts/GatewayFetchTarget.sol";
// import ENS
import {ENS} from "ens-contracts/registry/ENS.sol";
import {UtilsHooks} from "./utils/UtilsHooks.sol";
import {IExtensionResolver, ExtensionData} from "./IExtensionResolver.sol";

contract L1ExtensionsResolver is GatewayFetchTarget {
	using GatewayFetcher for GatewayRequest;

    using UtilsHooks for bytes; 

    // The ENS registry
    ENS _ens;

    // Extensions resolve hooks that use key-value pairs to resolve records from other 
    // resolvers than the user's resolver, and can even resolver data from other chains. The hook key 
    // starts with the domain name of the owner of the key, in reverse order, i.e. eth.dao.votes, 
    // where the owner of the extension eth.dao is the 'id' part of the key and 'votes' is the 'terminal key' part of the key. 
    mapping (string domain => IExtensionResolver extension) extensions;
 
	constructor(ENS ens) {
        _ens = ens;
	}

    // A function that allows the onwer or approved operator to add an extension to the resolver
    function addExtension(string memory domain, IExtensionResolver extension) public {

        // convert the domain, in reverse order, i.e. eth.dao to the DNS format of dao.eth. 
        bytes memory name = UtilsHooks.reverseStringToDNS(domain);

        // make the node from the name
        bytes32 node = name.namehash(0);

        // check to see if the msg.sender is the owner of the node or an approved operator
        require(_ens.owner(node) == msg.sender || _ens.isApprovedForAll(_ens.owner(node), msg.sender), "Not authorized to add extension");

        // add the extension to the resolver
        extensions[domain] = extension;
    }

    // A function that removes an extension from the resolver
    function removeExtension(string memory domain) public {
            
        // convert the domain, in reverse order, i.e. eth.dao to the DNS format of dao.eth. 
        bytes memory name = UtilsHooks.reverseStringToDNS(domain);

        // make the node from the name
        bytes32 node = name.namehash(0);

        // check to see if the msg.sender is the owner of the node or an approved operator
        require(_ens.owner(node) == msg.sender || _ens.isApprovedForAll(_ens.owner(node), msg.sender), "Not authorized to remove extension");

        // remove the extension from the resolver
        delete extensions[domain];
    }

    // We use a list of cointypes because we want to be able to get more records than one at a time. 
    function hook(bytes32 node, string calldata key, address resolver, uint256 coinType) public returns (string memory){  

        // split the key into the first two labels and the rest of the key i.e. eth.dao.votes.latest -> eth.dao, votes.latest
        (string memory domain, string memory terminalKey) = UtilsHooks.splitReverseDomain(key, 2);

        // check to make sure the extension exists
        require(address(extensions[domain]) != address(0), "Extension does not exist");

        // check to make sure the resolver is for this contract
        require(resolver == address(this), "Invalid resolver");

        // check to make sure the coinType is 60
        require(coinType == 60, "Invalid coinType");

        // USE UNRUGGABLE GATEWAYS here!!

        // We need to check the ENS L2 resolver (ENSProfile resolver) to make sure the user has added the extension.
        // We are currently skipping this step and assuming the user has added the extension.
        // Because we are not going to revert, we can just call the hookCallback function directly.

        // make an empty array of bytes values with a length of 1
        bytes[] memory values = new bytes[](1);

        // Set the first value to true
        values[0] = abi.encode(true);

        // make an ExtensionData struct
        ExtensionData memory extensionData = ExtensionData(node, terminalKey, address(extensions[domain]), new bytes[](0), 1);

        // encode the ExtensionData struct
        bytes memory extensionDataEncoded = abi.encode(extensionData);

        return this.hookCallback(values, 0, extensionDataEncoded);

    }

    function hookCallback(bytes[] calldata values, uint8, bytes calldata extraData) external returns (string memory) {

        // Make sure the extension is added.
        require(abi.decode(values[0], (bool)), "Hook not added");

        // decode the extraData into an ExtensionData struct
        ExtensionData memory extensionData = abi.decode(extraData, (ExtensionData));

        // call the extension resolver, if the call doesn't revert then return a string.
        return IExtensionResolver(extensionData.extensionResolver).resolveExtension(extensionData);
    }

    // This is the callback function of the extension resolver, which may may be called by the extension resolver
    function extensionCallback(bytes[] calldata values, uint8, bytes calldata extraData) external returns (string memory) {
        
        // decode the extraData into an ExtensionData struct
        ExtensionData memory extensionData = abi.decode(extraData, (ExtensionData));
        
        // if the cycle is 0, then the extension is complete, so return the value
        if (extensionData.cycle == 0) {
            return abi.decode(values[0], (string));
        }

        // build a new array of bytes that includes all the previous data bytes and add the new values
        bytes[] memory newData = new bytes[](extensionData.data.length + values.length);

        // put the old data values into the new data array
        for (uint256 i = 0; i < extensionData.data.length; i++) {
            newData[i] = extensionData.data[i];
        }

        // put the new values into the new data array
        for (uint256 i = 0; i < values.length; i++) {
            newData[extensionData.data.length + i] = values[i];
        }

        // set the extensionData data to the new data
        extensionData.data = newData;

        // update the cycle
        extensionData.cycle = extensionData.cycle + 1;

        // call the extension resolver, if the call doesn't revert then return a string.
        return IExtensionResolver(extensionData.extensionResolver).resolveExtension(extensionData);
    
    }


}