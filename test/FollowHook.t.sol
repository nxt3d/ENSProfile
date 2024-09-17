// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import "forge-std/Test.sol";
import "openzeppelin/contracts/access/IAccessControl.sol"; // Import IAccessControl for error selector
import {FollowHook} from "../src/FollowHook.sol";
import {StringUtilsHook} from "../src/StringUtilsHook.sol";

// Import ENS interfaces
import "ens-contracts/resolvers/profiles/IAddressResolver.sol";
import "ens-contracts/resolvers/profiles/IAddrResolver.sol";
import "ens-contracts/resolvers/profiles/ITextResolver.sol";
import "ens-contracts/resolvers/profiles/IExtendedResolver.sol";

contract FollowHookTest is Test {
    using StringUtilsHook for string;

    FollowHook followHook;

    address account1 = 0x0000000000000000000000000000000000003511;
    address account2 = 0x0000000000000000000000000000000000004612;
    address account3 = 0x0000000000000000000000000000000000005713;
    address hacker = 0x0000000000000000000000000000000000006874;

    bytes follow1 = bytes("Follow1");
    bytes follow2 = bytes("Follow2");
    bytes follow3 = bytes("Follow3");

    function setUp() public {
        followHook = new FollowHook();
    }

    function test1000________________________________________________________________________________() public {}
    function test2000__________________________FOLLOW_HOOK__________________________________________() public {}
    function test3000________________________________________________________________________________() public {}

    function test_001____addFollow_____________________FollowCanBeAdded() public {
        followHook.addFollow(follow1);
        uint256 totalFollows = followHook.totalFollows();
        assertEq(totalFollows, 1);
        assertEq(followHook.getFollowByIndex(0), follow1);
    }

    function test_002____addFollow_____________________UnauthorizedCaller_Reverts() public {
        vm.startPrank(hacker);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector, // Use IAccessControl selector
                hacker,
                followHook.ADMIN_ROLE()
            )
        );
        followHook.addFollow(follow1);
    }

    function test_003____removeFollowByIndex_____________________FollowCanBeRemoved() public {
        followHook.addFollow(follow1);
        followHook.addFollow(follow2);

        followHook.removeFollowByIndex(0);
        uint256 totalFollows = followHook.totalFollows();
        assertEq(totalFollows, 1);
        assertEq(followHook.getFollowByIndex(0), follow2);
    }

    function test_004____removeFollowByIndex_____________________UnauthorizedCaller_Reverts() public {
        followHook.addFollow(follow1);

        vm.startPrank(hacker);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector, // Use IAccessControl selector
                hacker,
                followHook.ADMIN_ROLE()
            )
        );
        followHook.removeFollowByIndex(0);
    }

    function test_005____removeFollowByIndex_____________________IndexOutOfBounds_Reverts() public {
        followHook.addFollow(follow1);
        followHook.addFollow(follow2);

        vm.expectRevert("Index out of bounds");
        followHook.removeFollowByIndex(2);
    }

    function test_006____text_____________________ReturnsFollowsList() public {
        followHook.addFollow(follow1);
        followHook.addFollow(follow2);
        followHook.addFollow(follow3);

        // Convert the address to string without the 0x prefix
        string memory addressString = StringUtilsHook.addressToString(address(followHook));

        // log the address of the followHook contract
        console.log("followHook address: %s", address(followHook));

        string memory key = string(abi.encodePacked("hook:follow:0,2:", addressString));
        string memory result = followHook.text(0x0, key);

        assertEq(result, '[Follow1,Follow2,Follow3]');
    }

      function test_007____text_____________________ReturnsPartialFollowsList() public {
        followHook.addFollow(follow1);
        followHook.addFollow(follow2);
        followHook.addFollow(follow3);

        // Convert the address to string without the 0x prefix
        string memory addressString = StringUtilsHook.addressToString(address(followHook));

        string memory key = string(abi.encodePacked("hook:follow:1,2:", addressString));
        string memory result = followHook.text(0x0, key);

        assertEq(result, '[Follow2,Follow3]');
    }

    function test_008____text_____________________InvalidAddress_Reverts() public {
        followHook.addFollow(follow1);
        followHook.addFollow(follow2);

        string memory key = "hook:follow:0,1:0000000000000000000000000000000000000000"; // No 0x prefix
        vm.expectRevert("Invalid hook address");
        followHook.text(0x0, key);
    }

    function test_009____text_____________________InvalidIndices_Reverts() public {
        followHook.addFollow(follow1);
        followHook.addFollow(follow2);

        string memory key = string(abi.encodePacked("hook:follow:0,2:", StringUtilsHook.addressToString(address(followHook))));
        vm.expectRevert("End index out of bounds");
        followHook.text(0x0, key);
    }

    function test_010____text_____________________MaxLengthExceeded_Reverts() public {
        followHook.addFollow(follow1);
        followHook.addFollow(follow2);

        string memory key = string(abi.encodePacked("hook:follow:0,21:", StringUtilsHook.addressToString(address(followHook))));
        vm.expectRevert("Max length of follows list is 21");
        followHook.text(0x0, key);
    }

    function test_011____addFollow_____________________MultipleFollowsCanBeAdded() public {
        followHook.addFollow(follow1);
        followHook.addFollow(follow2);
        followHook.addFollow(follow3);

        uint256 totalFollows = followHook.totalFollows();
        assertEq(totalFollows, 3);
        assertEq(followHook.getFollowByIndex(0), follow1);
        assertEq(followHook.getFollowByIndex(1), follow2);
        assertEq(followHook.getFollowByIndex(2), follow3);
    }

    function test_012____supportsInterface_____________________SupportsTextAndExtendedResolver() public {
        assertTrue(followHook.supportsInterface(type(ITextResolver).interfaceId));
        assertTrue(followHook.supportsInterface(type(IExtendedResolver).interfaceId));
    }

    function test_013____supportsInterface_____________________SupportsAccessControl() public {
        assertTrue(followHook.supportsInterface(type(IAccessControl).interfaceId));
    }

    function test_014____supportsInterface_____________________DoesNotSupportRandomInterface() public {
        bytes4 randomInterface = bytes4(keccak256("RandomInterface()"));
        assertFalse(followHook.supportsInterface(randomInterface));
    }

    function test_015____resolve_____________________ResolvesTextSelector() public {
        followHook.addFollow(follow1);

        bytes memory data = abi.encodeWithSelector(ITextResolver.text.selector, bytes32(0x0), "hook:follow:0,0:address");
        bytes memory result = followHook.resolve("", data);

        assertEq(abi.decode(result, (string)), "[Follow1]");
    }

}
