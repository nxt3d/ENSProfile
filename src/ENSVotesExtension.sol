// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;
 
import  "@unruggable/contracts/GatewayProtocol.sol";
import {GatewayFetcher, GatewayRequest} from "@unruggable/contracts/GatewayFetcher.sol";
import {GatewayFetchTarget, IGatewayProofVerifier} from "@unruggable/contracts/GatewayFetchTarget.sol";

import {ENS} from "ens-contracts/registry/ENS.sol";
import {BytesUtilsSub} from "./utils/BytesUtilsSub.sol";
import {Strings} from "openzeppelin/contracts/utils/Strings.sol";

import {IVotes} from "openzeppelin/contracts/governance/utils/IVotes.sol";

error OffchainLookup(
    address from,
    string[] urls,
    bytes request,
    bytes4 callback,
    bytes carry
);

struct ExtensionData {
    bytes32 node;
    string key;
    bytes[] data;
    uint256 cycle;
}
 
contract ENSVotesExtension is GatewayFetchTarget {
	using GatewayFetcher for GatewayRequest;

    using Strings for uint256;
    using Strings for string;
 
	IGatewayProofVerifier immutable _verifier;
	address immutable _exampleAddress;
    ENS _ens;
    IVotes _votes;

 
	constructor(IGatewayProofVerifier verifier, address exampleAddress, ENS ens, IVotes votes) {
		_verifier = verifier;
        _exampleAddress = exampleAddress;
        _ens = ens;
        _votes = votes;
	}
 
    function supportsInterface(bytes4 x) external pure returns (bool) {
		return x == 0x3b3b57de; //See https://docs.ens.domains/ensip/1
	}

    function resolveExtension(ExtensionData extensionData) public returns (string) {

        // If the cycle is 0, we need to resolve the Ethereum L1 address.
        if (extensionData.cycle == 0) {

            // Use Unruggable Gateways here to get the address of the node on coinType 60

            // Just for testing we are hard coding the address.
            address ethAddress = 0xb8c2C29ee19D8307cb7255e1Cd9CbDE883A267d5;

            // set the cointype to ETH: 60
            uint256 ethCoinType = 60;

            // decode the extraData into an ExtensionData struct
            ExtensionData memory extensionData = abi.decode(extraData, (ExtensionData));

            // make sure the terminal key matches "votes"
            

            // set the cycle to 1
            extensionData.cycle = 1;

            // make a empty set of gateway URLs
            string[] memory urls = new string[](0);

            // create an array of bytes for callDatas
            bytes[] memory callDatas = new bytes[](2);

            // set the first value to ethAddress
            callDatas[0] = abi.encode(ethAddress);

            // set the second value to ethCoinType
            callDatas[1] = abi.encode(ethCoinType);

            // encode the callDatas into callData
            bytes memory callData = abi.encode(callDatas);

            // encode the extensionData
            bytes memory exdDataBytes = abi.encode(extensionData);

            // revert with an offchain lookup
            revert OffchainLookup(
                address(this),
                urls,
                callData, // array callDatas as bytes
                this.hookCallback.selector,
                exdDataBytes // ExtensionData as bytes
            );
            
        }

        // If the cycle is 1 then we need to get the Ethereum address that was resolved, and get the 
        // number of ENS votes. 
        
        if (extensionData.cycle == 1) {

            // decode the address from the first value
            address ethAddress = abi.decode(values[0], (address));

            // decode the coinType from the second value
            uint256 ethCoinType = abi.decode(values[1], (uint256));

            // If the address is not 0, and the coinType is 60, then we can get the lates votes of the address 
            // from the ENS token contract.
            if (ethAddress != address(0) && ethCoinType == 60) {
                // get the votes from the ENS token contract
                uint256 votes = _votes.getVotes(ethAddress);

                // return the votes as a string
                return votes.toString();
            } else {
                // return an empty string
                return "";
            }
        }

        return "";

    }

}