// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import {Test, console} from "forge-std/Test.sol";
import {BytesUtilsSub} from "../src/utils/BytesUtilsSub.sol";
import {L1ExtensionsResolver} from "../src/L1ExtensionsResolver.sol";
import {ENSVotesExtension} from "../src/ENSVotesExtension.sol";
import {DummyENSToken} from "../src/dummyContracts/DummyENSToken.sol";

import {IVotes} from "openzeppelin/contracts/governance/utils/IVotes.sol";

import {ENSRegistry} from "ens-contracts/registry/ENSRegistry.sol";

import {IExtensionResolver, ExtensionData} from "../src/IExtensionResolver.sol";

error OffchainLookup(
    address from,
    string[] urls,
    bytes callData,
    bytes4 callback,
    bytes extraData
);

contract ENSVotesExtensionTest is Test {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    using BytesUtilsSub for bytes;

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
    ENSVotesExtension ensVotesExtension;
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

        // create a dummy ENS Token contract
        DummyENSToken dummyENSToken = new DummyENSToken();

        // create a ENSVotesExtension contract
        ensVotesExtension = new ENSVotesExtension(IVotes(address(dummyENSToken)));

        // register .eth in the ENS registry
        ens.setSubnodeOwner(0, keccak256("eth"), account);

        // set the subnode for ens.eth
        ens.setSubnodeOwner(ETH_NODE, keccak256("ens"), account);

        // register the eth.ens domain as an extension in the L1ExtensionsResolver,
        // set the extension to the ENSVotesExtension contract

        l1ExtensionsResolver.addExtension("eth.ens", IExtensionResolver(address(ensVotesExtension)));

    }

    function test1000________________________________________________________________________________() public {}

    function test2000__________________________ENS_VOTES_EXTENSION___________________________________() public {}

    function test3000________________________________________________________________________________() public {}

    function test_001____setAddr____________________________EthereumAddressCanBeSet() public {

        // make the node of nick.eth using "\04nick\x03eth\x00"
        bytes memory dnsNameNickEth = "\x04nick\x03eth\x00";
        bytes32 nodeNickEth = dnsNameNickEth.namehash(0);
        
        // resolve the hook for the eth.ens domain
        string memory result;
        try l1ExtensionsResolver.hook(nodeNickEth, "eth.ens.votes", address(l1ExtensionsResolver), 60) returns (string memory res) {
            result = res;
        } catch (bytes memory err) {
            if (err.length == 0) {
            revert("Unknown error");
            }
            
            // get the first 4 bytes and make sure it matches the signature of OffchainLookup
            bytes4 errorSig;
            assembly {
                errorSig := mload(add(err, 32))
            }
            if (errorSig == OffchainLookup.selector) {

                // remove the first 4 bytes of the error
                bytes memory errorDataBytes = new bytes(err.length - 4);
                for (uint i = 4; i < err.length; i++) {
                    errorDataBytes[i - 4] = err[i];
                }

                // get the offchain lookup error data as variables
                (address from, string[] memory urls, bytes memory callData, bytes4 callback, bytes memory extraData) = 
                    abi.decode(errorDataBytes, (address, string[], bytes, bytes4, bytes));

                // decode callData to bytes[] calldata values
                bytes[] memory values = abi.decode(callData, (bytes[]));

                // call the L1ExtensionsResolver ExtensionCallback function extensionCallback(bytes[] calldata values, uint8, bytes calldata extraData)
                string memory result = l1ExtensionsResolver.extensionCallback(values, 0, extraData);

                // check that the result is 130104422044868748111849
                assertEq(result, "130104422044868748111849");

            }

        }



    }

}
