// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;
 
import  "@unruggable/contracts/GatewayProtocol.sol";
import {GatewayFetcher, GatewayRequest} from "@unruggable/contracts/GatewayFetcher.sol";
import {GatewayFetchTarget, IGatewayProofVerifier} from "@unruggable/contracts/GatewayFetchTarget.sol";

import {ENS} from "ens-contracts/registry/ENS.sol";
import {BytesUtilsSub} from "utils/BytesUtilsSub.sol";

error OffchainLookup(
    address from,
    string[] urls,
    bytes request,
    bytes4 callback,
    bytes carry
);

struct ExtensionData {
    bytes32 node;
    address[] resolvedAddresses;
    uint256[] resolvedAddressCoinTypes;
    string key;
    address extensionResolver;
    bytes[] data;
    uint256 cycle;
}
 
contract ENSVotesExtension is GatewayFetchTarget {
	using GatewayFetcher for GatewayRequest;
 
	IGatewayProofVerifier immutable _verifier;
	address immutable _exampleAddress;
    ENS _ens;
 
	constructor(IGatewayProofVerifier verifier, address exampleAddress, ENS ens) {
		_verifier = verifier;
        _exampleAddress = exampleAddress;
        _ens = ens;


	}
 
    function supportsInterface(bytes4 x) external pure returns (bool) {
		return x == 0x3b3b57de; //See https://docs.ens.domains/ensip/1
	}

    function resolveExtension(ExtensionData extensionData) returns (string) {

        // If the cycle is 0, we need to resolve the Ethereum L1 address.
        if (extensionData.cycle == 0) {

            // As a hack, we are just calling the hookCallback function directly

            // create the a dummy address
            address ethAddress = 0x6b175474e89094c44da98b954eedeac495271d0f;

            // set the cointype to ETH: 60
            uint256 ethCoinType = 60;

            // decode the extraData into an ExtensionData struct
            ExtensionData memory exd = abi.decode(extraData, (ExtensionData));

            // set the cycle to 1
            exd.cycle = 1;

            // encode the address and cointype into a bytes value

            // USE UNRUGGABLE GATEWAYS here!!
            // We are using dummy data so won't use the gateways ATM.

            // make a empty set of gateway URLs
            string[] memory urls = new string[](0);

            // make resolvedAddresses bytes array with a length of 2
            bytes[] memory resolvedAddresses = new bytes[](2);

            // create an array of bytes for callDatas
            bytes[] memory callDatas = new bytes[](2);

            // set the first value to ethAddress
            callDatas[0] = abi.encode(ethAddress);

            // set the second value to ethCoinType
            callDatas[1] = abi.encode(ethCoinType);

            // encode the callDatas into callData
            bytes memory callData = abi.encode(callDatas);

            // encode the exd
            bytes memory exdData = abi.encode(exd);

            // revert with an offchain lookup
            revert OffchainLookup(
                address(this),
                urls,
                callData, // array callDatas as bytes
                this.hookCallback.selector,
                exdData // ExtensionData as bytes
            );
            
        }


    // This is a dummy function, used to create a function selector. 
    hookCallback(bytes[] calldata values, uint8, bytes calldata extraData) external returns (string) {
        return "" 
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