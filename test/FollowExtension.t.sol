// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import {Test, console} from "forge-std/Test.sol";
import {UtilsHook} from "../src/utils/UtilsHook.sol";
import {L1ExtensionsResolver} from "../src/L1ExtensionsResolver.sol";
import {FollowExtension} from "../src/extensions/FollowExtension.sol";

import {ENSRegistry} from "ens-contracts/registry/ENSRegistry.sol";

import {IExtensionResolver, ExtensionData} from "../src/extensions/IExtensionResolver.sol";

error OffchainLookup(
    address from,
    string[] urls,
    bytes callData,
    bytes4 callback,
    bytes extraData
);

contract FollowExtensionTest is Test {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    using UtilsHook for bytes;

    uint64 twoYears = 63072000; // Approximately 2 years
    uint64 oneYear = 31536000; // A year in seconds.
    uint64 oneMonth = 2592000; // A month in seconds.
    uint64 oneDay = 86400; // A day in seconds.

    address account = 0x0000000000000000000000000000000000003511;
    address account2 = 0x0000000000000000000000000000000000004612;
    address account3 = 0x0000000000000000000000000000000000005713;
    address hacker = 0x0000000000000000000000000000000000006874;
    address resolver = 0x0000000000000000000000000000000000007365;
    address resolver2 = 0x0000000000000000000000000000000000008246;
    address renewalController = account3;

    uint64 public constant startTime = 1641070800;

    L1ExtensionsResolver l1ExtensionsResolver;
    FollowExtension followExtension;
    ENSRegistry ens;

    bytes32 private constant ETH_NODE = 0x93cdeb708b7545dc668eb9280176169d1c33cfd8ed6f04690a0bcc88a93fc4ae;

    function setUp() public {
        vm.warp(startTime);
        vm.startPrank(account);

        vm.deal(account, 100 ether);

        // create a ENS registry contract
        ens = new ENSRegistry();

        // create a L1ExtensionsResolver contract
        l1ExtensionsResolver = new L1ExtensionsResolver(ens);

        // register .eth in the ENS registry
        ens.setSubnodeOwner(0, keccak256("eth"), account);

        // set the subnode for ens.eth
        ens.setSubnodeOwner(ETH_NODE, keccak256("follow"), account);

        // create a FollowExtension contract
        followExtension = new FollowExtension();

        // create a follow list for the account using addFollowBatch(bytes[] calldata followRecords) using fake accounts
        bytes[] memory followRecords = new bytes[](3);
        followRecords[0] = abi.encode(account2);
        followRecords[1] = abi.encode(account3);
        followRecords[2] = abi.encode(hacker);

        followExtension.addFollowBatch(followRecords);

        // register the eth.ens domain as an extension in the L1ExtensionsResolver,
        // set the extension to the ENSVotesExtension contract

        l1ExtensionsResolver.addExtension("eth.follow", IExtensionResolver(address(followExtension)));

        // check to make sure the follow extension exists
        require(address(l1ExtensionsResolver.extensions("eth.follow")) != address(0), "Extension does not exist");

    }

    function test1000________________________________________________________________________________() public {}
    function test2000__________________________FOLLOW_EXTENSION______________________________________() public {}
    function test3000________________________________________________________________________________() public {}

    function test_001____hook_______________________________CanGetFirstPageOfFollows() public {

        // make the node of nick.eth using "\04nick\x03eth\x00"
        bytes memory dnsNameNameEth = "\x04name\x03eth\x00";
        bytes32 nodeNameEth = dnsNameNameEth.namehash(0);
        
        // resolve the hook for the eth.ens domain
        string memory result;
        try l1ExtensionsResolver.hook(nodeNameEth, "eth.follow.0", address(l1ExtensionsResolver), 60) returns (string memory res) {
            result = res;
        } catch (bytes memory err) {
            // catch the error (There was a revert, possibly due to an OffchainLookup)

            // make sure the error is not empty
            if (err.length == 0) {
            revert("Unknown error");
            }
            
            // get the error signature
            bytes4 errorSig;
            assembly {
                errorSig := mload(add(err, 32))
            }

            // If the error was an OffchainLookup error
            if (errorSig == OffchainLookup.selector) {
                // Note: Normally the OffchainLookup error would be handled by the client, which 
                // would relay the error data to a gateway, which would then fetch the data
                // and return the data to the callback function. 

                // In this case, for testing we are simply returning the data directly. 

                // remove the first 4 bytes of the error
                bytes memory errorDataBytes = new bytes(err.length - 4);
                for (uint i = 4; i < err.length; i++) {
                    errorDataBytes[i - 4] = err[i];
                }

                // get the offchain lookup error data as variables
                (address from, string[] memory urls, bytes memory callData, bytes4 callback, bytes memory extraData) = 
                    abi.decode(errorDataBytes, (address, string[], bytes, bytes4, bytes));

                // decode calldata to bytes[] calldata values, values[0] contains the resolved address of the node in bytes.
                bytes[] memory values = abi.decode(callData, (bytes[]));

                // set the third value of the values to the encoded value of the accont address
                values[0] = abi.encode(account);

                // call the L1ExtensionsResolver ExtensionCallback function extensionCallback(bytes[] calldata values, uint8, bytes calldata extraData)
                string memory result = l1ExtensionsResolver.extensionCallback(values, 0, extraData);

                // check that the result is [0x00...4612,0x00...5713,0x00...6874]
                assertEq(result, "[0x0000000000000000000000000000000000004612,0x0000000000000000000000000000000000005713,0x0000000000000000000000000000000000006874]");

            }

        }



    }

}
