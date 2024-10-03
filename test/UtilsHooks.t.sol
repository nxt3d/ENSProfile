// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import {Test, console} from "forge-std/Test.sol";
import {UtilsHooks} from "../src/utils/UtilsHooks.sol";
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

contract UtilsHooksTest is Test {

    using UtilsHooks for bytes;

    bytes32 private constant ETH_NODE = 0x93cdeb708b7545dc668eb9280176169d1c33cfd8ed6f04690a0bcc88a93fc4ae;

    function setUp() public {

    }

    function test1000________________________________________________________________________________() public {}

    function test2000__________________________UTILS_HOOKS___________________________________________() public {}

    function test3000________________________________________________________________________________() public {}

    function test_001____DNSToReverseString_________________ConvertsADNSNameToAReverseDomainString() public {

        // Create a DNS name for nick.eth
        bytes memory dnsNameNickEth = "\x04nick\x03eth\x00";

        string memory reverseString = UtilsHooks.DNSNameToReverseString(dnsNameNickEth);

        // Make sure the reverse string is correct, i.e. eth.nick
        assertEq(reverseString, "eth.nick");

        // Creat the DNS name for votes.ens.eth
        bytes memory dnsNameVotesEnsEth = "\x05votes\x03ens\x03eth\x00";

        reverseString = UtilsHooks.DNSNameToReverseString(dnsNameVotesEnsEth);

        // Make sure the reverse string is correct, i.e. eth.ens.votes
        assertEq(reverseString, "eth.ens.votes");

        // Creat the DNS name for 😀._tricky.101
        bytes memory dnsNameTricky = "\x04\xf0\x9f\x98\x80\x07_tricky\x03\x31\x30\x31\x00";

        reverseString = UtilsHooks.DNSNameToReverseString(dnsNameTricky);

        // Make sure the reverse string is correct, i.e. 101.tricky.😀
        assertEq(reverseString, unicode"101._tricky.😀");

    }

    // make sure that reverseStringToDNS works 
    function test_002____ReverseStringToDNS_________________ConvertsAReverseDomainStringToADNSName() public {

        // Create a reverse string for eth.nick
        string memory reverseString = "eth.nick";

        bytes memory dnsNameNickEth = UtilsHooks.reverseStringToDNS(reverseString);

        // Make sure the DNS name is correct, i.e. "\x04nick\x03eth\x00"
        assertEq(dnsNameNickEth, "\x04nick\x03eth\x00");

        // Create a reverse string for eth.ens.votes
        reverseString = "eth.ens.votes";

        bytes memory dnsNameVotesEnsEth = UtilsHooks.reverseStringToDNS(reverseString);

        // Make sure the DNS name is correct, i.e. "\x05votes\x03ens\x03eth\x00"
        assertEq(dnsNameVotesEnsEth, "\x05votes\x03ens\x03eth\x00");

        // Create a reverse string for 101._tricky.😀
        reverseString = unicode"101._tricky.😀";

        bytes memory dnsNameTricky = UtilsHooks.reverseStringToDNS(reverseString);

        // Make sure the DNS name is correct, i.e. "\x04\xf0\x9f\x98\x80\x07_tricky\x03\x31\x30\x31\x00"
        assertEq(dnsNameTricky, "\x04\xf0\x9f\x98\x80\x07_tricky\x03\x31\x30\x31\x00");

    }

    // make a test for splitReverseDomain(string memory reverseDomain, uint256 numLabels)
    function test_003____SplitReverseDomain_________________SplitsAReverseDomainStringIntoTwoParts() public {

        // Create a reverse string for eth.nick
        string memory reverseString = "eth.nick";

        (string memory domain, string memory terminalKey) = UtilsHooks.splitReverseDomain(reverseString, 1);

        // Make sure the domain is correct, i.e. eth
        assertEq(domain, "eth");

        // Make sure the terminal key is correct, i.e. nick
        assertEq(terminalKey, "nick");

        // Create a reverse string for eth.ens.votes
        reverseString = "eth.ens.votes";

        (domain, terminalKey) = UtilsHooks.splitReverseDomain(reverseString, 2);

        // Make sure the domain is correct, i.e. eth.ens
        assertEq(domain, "eth.ens");

        // Make sure the terminal key is correct, i.e. votes
        assertEq(terminalKey, "votes");

        // Create a reverse string for 101._tricky.😀
        reverseString = unicode"101._tricky.😀";

        (domain, terminalKey) = UtilsHooks.splitReverseDomain(reverseString, 1);

        // Make sure the domain is correct, i.e. 101
        assertEq(domain, "101");

        // Make sure the terminal key is correct, i.e. _tricky.😀
        assertEq(terminalKey, unicode"_tricky.😀");

    }

}
