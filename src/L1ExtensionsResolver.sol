// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;
 
import  "@unruggable/contracts/GatewayProtocol.sol";
import {GatewayFetcher, GatewayRequest} from "@unruggable/contracts/GatewayFetcher.sol";
import {GatewayFetchTarget, IGatewayProofVerifier} from "@unruggable/contracts/GatewayFetchTarget.sol";
 
contract L1ExtensionsResolver is GatewayFetchTarget {
	using GatewayFetcher for GatewayRequest;
 
	IGatewayProofVerifier immutable _verifier;
	address immutable _exampleAddress;
 
	constructor(IGatewayProofVerifier verifier, address exampleAddress) {
		_verifier = verifier;
        _exampleAddress = exampleAddress;
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