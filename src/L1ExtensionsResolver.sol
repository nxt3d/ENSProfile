// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;
 
import  "@unruggable/contracts/GatewayProtocol.sol";
import {GatewayFetcher, GatewayRequest} from "@unruggable/contracts/GatewayFetcher.sol";
import {GatewayFetchTarget, IGatewayProofVerifier} from "@unruggable/contracts/GatewayFetchTarget.sol";
// import ENS
import {ENS} from "ens-contracts/registry/ENS.sol";
import {BytesUtilsSub} from "utils/BytesUtilsSub.sol";

interface IExtensionResolver {
    function resolveExtension(bytes32 node, string calldata key, address resolver, uint256 coinType) external returns (string);
    function extensionCallback(bytes[] calldata values, uint8, bytes calldata extraData) external returns (string);
}

struct ExtensionData {
    bytes32 node;
    address addr;
    string key;
    address resolver;
    uint256 coinType;
    bytes[] data;
    uint256 cycle;
}

contract L1ExtensionsResolver is GatewayFetchTarget {
	using GatewayFetcher for GatewayRequest;

    using BytesUtilsSub for bytes; 

	IGatewayProofVerifier immutable _verifier;
	address immutable _exampleAddress;

    // The ENS registry
    ENS _ens;

    // Extensions are hooks that use key-value pairs to be able to resolve records from other 
    // resolvers, even from other chains. The hook key starts with the domain name of the owner of the 
    // key, in reverse order, i.e. eth.dao.votes, where the owner of the extension is eth.dao is the key
    // and 'votes' is the extension terminal key. 
    mapping (string domain => IExtensionResolver extension) extensions;
 
	constructor(IGatewayProofVerifier verifier, address exampleAddress, ENS ens) {
        _ens = ens;
		_verifier = verifier;
        _exampleAddress = exampleAddress;
	}

    // A function that allows the onwer or approved operator to add an extension to the resolver
    function addExtension(sting domain, IExtensionResolver extension) public {

        // convert the domain, in reverse order, i.e. eth.dao to the DNS format of dao.eth. 
        bytes memory name = BytesUtilsSub.reverseStringToDNS(domain);

        // make the node from the name
        bytes32 node = BytesUtilsSub.namehash(name);

        // check to see if the msg.sender is the owner of the node or an approved operator
        require(_ens.owner(node) == msg.sender || _ens.isApprovedForAll(_ens.owner(node), msg.sender), "Not authorized to add extension");

        // add the extension to the resolver
        extensions[domain] = extension;
    }

    // A function that removes an extension from the resolver
    function removeExtension(string domain) public {
            
        // convert the domain, in reverse order, i.e. eth.dao to the DNS format of dao.eth. 
        bytes memory name = BytesUtilsSub.reverseStringToDNS(domain);

        // make the node from the name
        bytes32 node = BytesUtilsSub.namehash(name);

        // check to see if the msg.sender is the owner of the node or an approved operator
        require(_ens.owner(node) == msg.sender || _ens.isApprovedForAll(_ens.owner(node), msg.sender), "Not authorized to remove extension");

        // remove the extension from the resolver
        delete extensions[domain];
    }


    function hook(bytes32 node, address addr, string calldata key, address resolver) returns (string) {  

        // split the key into the first two labels and the rest of the key i.e. eth.dao.votes.latest -> eth.dao, votes.latest
        (string memory domain, string memory terminalKey) = BytesUtilsSub.splitKey(key, 2);

        // check to make sure the extension exists
        require(extensions[domain] != address(0), "Extension does not exist");

        // check ENS L2 to make sure the user has added the hook
        // Note: Currently this is being ignored but will need to be implemented

        // As a hack, we are just calling the hookCallback function directly

        // a new empty bytes array with length 0
        bytes[] memory empty = new bytes[](0);
        buyts[] values = new bytes[](1);
        
        // set the first value to 1 i.e. true
        values[0] = abi.encode(true);
        

        return hookCallback(values, 0, abi.encode(ExtensionData(address, terminalKey, resolver, coinType, empty, 0));
        
    }

    hookCallback(bytes[] calldata values, uint8, bytes calldata extraData) external returns (string) {

        // Make sure the hook is added.
        require(abi.decode(values[0], (bool)), "Hook not added");

        // call resolveExtension
        return extensions[domain].resolveExtension(abi.decode(extraData, (ExtensionData));
    }

    // This is the callback function of the extension resolver, which may be called by the extension resolver)
    function extensionCallback(bytes[] calldata values, uint8 error, bytes calldata extraData) external returns (string) {
        
        // If the resolution is not done it will return a continue error
        uint256 CONTINUE_ERROR = 7;

        if (error == CONTINUE_ERROR) {

            // decode the extraData into an ExtensionData struct
            ExtensionData memory ed = abi.decode(extraData, (ExtensionData));

            // continue to the next cycle, if complete, return the values. 
            (bytes[] memory returnValues, , , ) = extensions[domain].resolveExtension(ed.node, ed.key, ed.resolver, ed.coinType, ed.data, ed.cycle + 1);
        } else {
            // we don't need to call the extension again so just return the values
            return abi.decode(values[0], (string));
        }

        // The call to the extension didn't revert so return the value.  
        return abi.decode(returnValues[0], (string));
    
    }
 
    function supportsInterface(bytes4 x) external pure returns (bool) {
		return x == 0x3b3b57de; //See https://docs.ens.domains/ensip/1
	}
 
    function addr(bytes32 node) public view returns (address) {
 
        GatewayRequest memory r = GatewayFetcher
            .newRequest(1)
            .setTarget(_exampleAddress)
            .setSlot(11)
            .read()
            .debug("lol")
            .setOutput(0);
 
		fetch(_verifier, r, this.addrCallback.selector, '');    
	}
	
    function addrCallback(bytes[] calldata values, uint8, bytes calldata extraData) external pure returns (address) {
        return abi.decode(values[0], (address));
	}
}