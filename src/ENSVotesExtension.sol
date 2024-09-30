// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;
 
import  "@unruggable/contracts/GatewayProtocol.sol";
import {GatewayFetcher, GatewayRequest} from "@unruggable/contracts/GatewayFetcher.sol";
import {GatewayFetchTarget, IGatewayProofVerifier} from "@unruggable/contracts/GatewayFetchTarget.sol";

import {ENS} from "ens-contracts/registry/ENS.sol";
import {BytesUtilsSub} from "utils/BytesUtilsSub.sol";
 
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

    function resolveExtension(bytes32 node, string calldata key, address resolver, uin256 coinType, bytes[] data, uint256 cycle) returns (string) {

        // the first item in the data array is a resolved address
        // if this is the first cycle, then we need to resolve the L1 address of the name. 

        _ens.resolver(node).addr(node);
        



        



 
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