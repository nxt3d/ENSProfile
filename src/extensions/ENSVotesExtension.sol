// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;
 
import  "@unruggable/contracts/GatewayProtocol.sol";
import {ENS} from "ens-contracts/registry/ENS.sol";
import {Strings} from "openzeppelin/contracts/utils/Strings.sol";

import {IVotes} from "openzeppelin/contracts/governance/utils/IVotes.sol";
import {IExtensionResolver, ExtensionData} from "../IExtensionResolver.sol";

error OffchainLookup(
    address from,
    string[] urls,
    bytes callData,
    bytes4 callback,
    bytes extraData
);

contract ENSVotesExtension is IExtensionResolver {

    using Strings for uint256;
    using Strings for string;
 
    IVotes _votes;

 
	constructor(IVotes votes) {
        _votes = votes;
	}
 
    function supportsInterface(bytes4 x) external pure returns (bool) {
		return x == 0x3b3b57de; //See https://docs.ens.domains/ensip/1
	}

    function resolveExtension(ExtensionData memory extensionData) public view returns (string memory) {

        // If the cycle is 1, we need to resolve the Ethereum L1 address.
        if (extensionData.cycle == 1) {

            // Use Unruggable Gateways here to get the address of the node on coinType 60, and also
            // make sure that the address's primary name is set to the node. 

            // Just for testing we are hard coding the address.
            address ethAddress = 0xb8c2C29ee19D8307cb7255e1Cd9CbDE883A267d5;

            // set the cointype to ETH: 60
            uint256 ethCoinType = 60;

            // make sure the terminal key matches "votes"
            require(extensionData.key.equal("votes"), "Invalid key");

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
                this.extensionCallback.selector,
                exdDataBytes // ExtensionData as bytes
            );
            
        }

        // If the cycle is 2 then we need to get the Ethereum address that was resolved, and get the 
        // number of ENS votes. 
        if (extensionData.cycle == 2) {

            // decode the address from the first value
            address ethAddress = abi.decode(extensionData.data[0], (address));

            // decode the coinType from the second value
            uint256 ethCoinType = abi.decode(extensionData.data[1], (uint256));

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

    // This is a dummy funciont, which is just needed to create a selector
    function extensionCallback(bytes[] calldata, uint8, bytes calldata) external pure returns (string memory) {
        return "";
    }

}