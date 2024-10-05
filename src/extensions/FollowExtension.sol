// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "openzeppelin/contracts/utils/introspection/ERC165.sol";
import "openzeppelin/contracts/access/AccessControl.sol";
import "openzeppelin/contracts/utils/Strings.sol";
import "../utils/StringUtilsHook.sol";  // Import the utility library
import "../utils/UtilsHook.sol";  // Import the utility library

import {IExtensionResolver, ExtensionData} from "../IExtensionResolver.sol";

error OffchainLookup(
    address from,
    string[] urls,
    bytes callData,
    bytes4 callback,
    bytes extraData
);

contract FollowExtension is AccessControl, IExtensionResolver {
    using StringUtilsHook for string;
    using UtilsHook for string;
    using Strings for address;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    mapping(address => bytes[] followList) follows;  

    // The length of a follows list page
    uint256 public pageLength = 10;

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
    }

    event FollowRecordAdded(bytes indexed followRecord);
    event FollowRecordRemoved(bytes indexed followRecord);

    function addFollow(bytes calldata followRecord) external {
        follows[msg.sender].push(followRecord);
        emit FollowRecordAdded(followRecord);
    }

    // add follow batch function
    function addFollowBatch(bytes[] calldata followRecords) external{
        for (uint256 i = 0; i < followRecords.length; i++) {
            follows[msg.sender].push(followRecords[i]);
            emit FollowRecordAdded(followRecords[i]);
        }
    }

    // add a function that adds bytes to the request data to the 

    // remove follow by index using the swap and pop method
    function removeFollowByIndex(uint256 index) external {

        // If the length of the list is 0, return an error
        require(follows[msg.sender].length > 0, "No follow records");

        // Ensure the index is within the bounds of the follow list
        require(index < follows[msg.sender].length, "Index out of bounds");

        // Get the follow list for the sender
        bytes[] storage followList = follows[msg.sender];

        // Emit an event before removing the follow record
        emit FollowRecordRemoved(followList[index]);

        // If the index is not the last element, swap it with the last element
        if (index < followList.length - 1) {
            followList[index] = followList[followList.length - 1];
        }

        // Remove the last element (which is now the element to be removed)
        followList.pop();
    }

    function getFollowByIndex(address addr, uint256 index) external view returns (bytes memory) {
        require(index < follows[addr].length, "Index out of bounds");
        return follows[addr][index];
    }

    function totalFollows(address addr) external view returns (uint256) {
        return follows[addr].length;
    }

    function resolveExtension(ExtensionData memory extensionData) external view override returns (string memory) {

        // if the cycle is set to 1 
        if (extensionData.cycle == 1) {

            // if at least the first character of the paramsKeyBytes is a number then 
            // convert the number to an integer
            uint256 page;
            if(uint8(bytes(extensionData.key)[0]) >= 48 && uint8(bytes(extensionData.key)[0]) <= 57) {
                page = extensionData.key.parseUint();
            }

            // create a start and end index for the page
            uint256 start = page * pageLength;
            uint256 end = start + pageLength - 1;

            // Store the start and end index in a bytes array
            bytes[] memory startEnd = new bytes[](2);
            startEnd[0] = abi.encode(start);
            startEnd[1] = abi.encode(end);

            // set the extensionData.data to the start and end array 
            extensionData.data = startEnd; 

            // use Unruggable Gateways here to get the address of the node on coinType 60
            // for this example we will just revert with the data

            // encode the extensionData
            bytes memory exdDataBytes = abi.encode(extensionData);

            // create a bytes array with one value, msg.sender
            bytes[] memory values = new bytes[](1);
            values[0] = abi.encode(extensionData.node);

            // encode the values
            bytes memory callDatas = abi.encode(values);

            // make a empty string array for the urls
            string[] memory urls = new string[](0);

            // revert with an offchain lookup
            revert OffchainLookup(
                address(this),
                urls,
                callDatas, // array callDatas as bytes
                this.extensionCallback.selector,
                exdDataBytes // ExtensionData as bytes
            );
        }

        // if the cycle is 2 then we now have a extensionData.data that contains, the start and end index, and the resolved address of the node
        // use this info to get the follow list
        if (extensionData.cycle == 2) {

            // get the start and end index
            uint256 start = abi.decode(extensionData.data[0], (uint256));
            uint256 end = abi.decode(extensionData.data[1], (uint256));

            // get the resolved address of the node
            address resolvedAddress = abi.decode(extensionData.data[2], (address));

            // get the follow list for the resolved address
            bytes[] memory followsList = follows[resolvedAddress];

            // if the start of the follow list does not fit within the list then just return nothing.                
            if (start >= followsList.length) {
                return "";
            }
            
            // If the end is greater than the length of the follow list,
            // change the end to be the last item of the list, as long as
            // the start is less than the length of the follow list. 
            if (end >= followsList.length && followsList.length - 1 >= start) {
                end = followsList.length - 1;
            }

            // create a new array to store the follow list for the page
            bytes[] memory pageFollowsList = new bytes[](end - start + 1);

            // copy the follow list for the page
            for (uint256 i = 0; i < pageFollowsList.length; i++) {
                pageFollowsList[i] = followsList[start + i];
            }

            // encode the follow list for the page
            string memory result = _encodeFollows(pageFollowsList);

            return result;
        }

        return "";
    }


    function _encodeFollows(bytes[] memory followsList) private pure returns (string memory) {
        string memory result = "[";

        for (uint256 i = 0; i < followsList.length; i++) {

            // get the address encoded as bytes and convert it to a string
            address addr = abi.decode(followsList[i], (address));
            string memory addrStr = addr.toHexString();

            result = string(abi.encodePacked(result, addrStr));
            if (i < followsList.length - 1) {
                result = string(abi.encodePacked(result, ","));
            }
        }

        return string(abi.encodePacked(result, "]"));
    }

    // This is a dummy funciont, which is just needed to create a selector
    function extensionCallback(bytes[] calldata, uint8, bytes calldata) external pure returns (string memory) {
        return "";
    }
}
