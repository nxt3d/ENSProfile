// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import {Test, console} from "forge-std/Test.sol";
import {BytesUtils} from "ens-contracts/utils/BytesUtils.sol";
import {ENSProfile} from "../src/ENSProfile.sol";

// Import ENS interfaces
import "ens-contracts/resolvers/profiles/IAddressResolver.sol";
import "ens-contracts/resolvers/profiles/IAddrResolver.sol";
import "ens-contracts/resolvers/profiles/ITextResolver.sol";
import "ens-contracts/resolvers/profiles/IExtendedResolver.sol";

struct ResolverStorage {
    mapping(uint256 => bytes) addresses;
    mapping(string => string) textRecords;
}

error AccessControlUnauthorizedAccount(address account, bytes32 neededRole);

contract ENSProfileTest is Test {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    using BytesUtils for bytes;

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

    ENSProfile ensProfile;

    function setUp() public {
        vm.warp(startTime);
        vm.startPrank(account);

        vm.deal(account, 100 ether);

        ensProfile = new ENSProfile();
    }

    function test1000________________________________________________________________________________() public {}

    function test2000__________________________ENS_PROFILE___________________________________________() public {}

    function test3000________________________________________________________________________________() public {}

    function test_001____setAddr____________________________EthereumAddressCanBeSet() public {
        ensProfile.setAddr(account2);
        assertEq(ensProfile.addr(bytes32(0x0)), account2);
    }

    function test_002____setAddr____________________________UnauthorizedCaller_Reverts() public {
        vm.stopPrank();
        vm.startPrank(hacker);

        vm.expectRevert(
            abi.encodeWithSelector(
                AccessControlUnauthorizedAccount.selector,
                hacker,
                ADMIN_ROLE
            )
        );
        ensProfile.setAddr(account2);
    }

    function test_003____setAddr____________________________CoinType_AddressCanBeSet() public {
        uint256 coinType = 1;
        bytes memory addressData = hex"1234567890abcdef";

        ensProfile.setAddr(coinType, addressData);

        assertEq(ensProfile.addr(bytes32(0x0), coinType), addressData);
    }

    function test_004____setAddr____________________________CoinType_UnauthorizedCaller_Reverts() public {
        vm.stopPrank();
        vm.startPrank(hacker);

        uint256 coinType = 1;
        bytes memory addressData = hex"1234567890abcdef";

        vm.expectRevert(
            abi.encodeWithSelector(
                AccessControlUnauthorizedAccount.selector,
                hacker,
                ADMIN_ROLE
            )
        );
        ensProfile.setAddr(coinType, addressData);
    }

    function test_005____setText____________________________RecordCanBeSet() public {
        string memory key = "url";
        string memory value = "https://example.com";

        ensProfile.setText(key, value);

        assertEq(ensProfile.text(bytes32(0x0), key), value);
    }

    function test_006____setText____________________________UnauthorizedCaller_Reverts() public {
        vm.stopPrank();
        vm.startPrank(hacker);

        string memory key = "url";
        string memory value = "https://example.com";

        vm.expectRevert(
            abi.encodeWithSelector(
                AccessControlUnauthorizedAccount.selector,
                hacker,
                ADMIN_ROLE
            )
        );
        ensProfile.setText(key, value);
    }

    function test_007____addExtension_______________________ExtensionCanBeAdded() public {
        ensProfile.addExtension("eth.extension");
        assertTrue(ensProfile.isExtensionActive("eth.extension"));
    }

    function test_008____addExtension_______________________UnauthorizedCaller_Reverts() public {
        vm.stopPrank();
        vm.startPrank(hacker);

        vm.expectRevert(
            abi.encodeWithSelector(
                AccessControlUnauthorizedAccount.selector,
                hacker,
                ADMIN_ROLE
            )
        );
        ensProfile.addExtension("eth.extension");
    }

    function test_009____removeExtension____________________ExtensionCanBeRemoved() public {
        ensProfile.addExtension("eth.extension");
        assertTrue(ensProfile.isExtensionActive("eth.extension"));
        ensProfile.removeExtension("eth.extension");
        assertFalse(ensProfile.isExtensionActive("eth.extension"));
    }

    function test_010____removeExtension____________________UnauthorizedCaller_Reverts() public {
        ensProfile.addExtension("eth.extension");

        vm.stopPrank();
        vm.startPrank(hacker);

        vm.expectRevert(
            abi.encodeWithSelector(
                AccessControlUnauthorizedAccount.selector,
                hacker,
                ADMIN_ROLE
            )
        );
        ensProfile.removeExtension("eth.extension");
    }

    function test_011____isExtensionActive__________________ReturnsCorrectStatus() public {
        ensProfile.addExtension("eth.extension");
        assertTrue(ensProfile.isExtensionActive("eth.extension"));

        ensProfile.removeExtension("eth.extension");
        assertFalse(ensProfile.isExtensionActive("eth.extension"));
    }

    function test_012____supportsInterface__________________ChecksCorrectly() public {
        bool isSupported = ensProfile.supportsInterface(type(IAddrResolver).interfaceId);
        assertTrue(isSupported);

        isSupported = ensProfile.supportsInterface(type(IAddressResolver).interfaceId);
        assertTrue(isSupported);

        isSupported = ensProfile.supportsInterface(type(ITextResolver).interfaceId);
        assertTrue(isSupported);

        isSupported = ensProfile.supportsInterface(type(IExtendedResolver).interfaceId);
        assertTrue(isSupported);
    }

    function test_013____resolve____________________________AddrSelector_ReturnsCorrectData() public {
        ensProfile.setAddr(account2);

        bytes memory data = abi.encodeWithSelector(IAddrResolver.addr.selector, bytes32(0x0));
        bytes memory result = ensProfile.resolve("", data);

        address returnedAddr = abi.decode(result, (address));
        assertEq(returnedAddr, account2);
    }

    function test_014____resolve____________________________AddrWithCoinTypeSelector_ReturnsCorrectData() public {
        uint256 coinType = 1;
        bytes memory addressData = hex"1234567890abcdef";
        ensProfile.setAddr(coinType, addressData);

        bytes memory data = abi.encodeWithSelector(IAddressResolver.addr.selector, bytes32(0x0), coinType);
        bytes memory result = ensProfile.resolve("", data);

        bytes memory returnedData = abi.decode(result, (bytes));
        assertEq(returnedData, addressData);
    }

    function test_015____resolve____________________________TextSelector_ReturnsCorrectData() public {
        string memory key = "url";
        string memory value = "https://example.com";
        ensProfile.setText(key, value);

        bytes memory data = abi.encodeWithSelector(ITextResolver.text.selector, bytes32(0x0), key);
        bytes memory result = ensProfile.resolve("", data);

        string memory returnedValue = abi.decode(result, (string));
        assertEq(returnedValue, value);
    }

    function test_016____resolve____________________________UnsupportedSelector_Reverts() public {
        bytes4 unsupportedSelector = bytes4(keccak256("nonexistentFunction()"));
        bytes memory data = abi.encodeWithSelector(unsupportedSelector);

        vm.expectRevert("Unsupported function selector");
        ensProfile.resolve("", data);
    }

    function test_017____setAddr____________________________MultipleCoinTypes() public {
        uint256 coinType1 = 1;
        uint256 coinType2 = 2;
        bytes memory addressData1 = hex"abcdef";
        bytes memory addressData2 = hex"123456";

        ensProfile.setAddr(coinType1, addressData1);
        ensProfile.setAddr(coinType2, addressData2);

        assertEq(ensProfile.addr(bytes32(0x0), coinType1), addressData1);
        assertEq(ensProfile.addr(bytes32(0x0), coinType2), addressData2);
    }

    function test_018____setText____________________________MultipleKeys() public {
        string memory key1 = "url";
        string memory value1 = "https://example1.com";
        string memory key2 = "description";
        string memory value2 = "An example description";

        ensProfile.setText(key1, value1);
        ensProfile.setText(key2, value2);

        assertEq(ensProfile.text(bytes32(0x0), key1), value1);
        assertEq(ensProfile.text(bytes32(0x0), key2), value2);
    }

    function test_019____setAddr____________________________CoinType_InvalidData() public {
        uint256 coinType = 1;
        bytes memory invalidData = hex"";

        ensProfile.setAddr(coinType, invalidData);

        assertEq(ensProfile.addr(bytes32(0x0), coinType), invalidData);
    }

    function test_020____addr_______________________________NoData_ReturnsZeroAddress() public {
        assertEq(ensProfile.addr(bytes32(0x0)), address(0));
    }

    function test_021____addr_______________________________CoinType_NoData_ReturnsEmpty() public {
        uint256 coinType = 1;
        bytes memory result = ensProfile.addr(bytes32(0x0), coinType);

        assertEq(result.length, 0);
    }

    function test_022____text_______________________________NoData_ReturnsEmptyString() public {
        string memory key = "nonexistent";
        string memory result = ensProfile.text(bytes32(0x0), key);

        assertEq(bytes(result).length, 0);
    }

    function test_023____setText____________________________EmptyKey_SetsSuccessfully() public {
        string memory key = "";
        string memory value = "Some value";

        ensProfile.setText(key, value);

        assertEq(ensProfile.text(bytes32(0x0), key), value);
    }

    function test_024____setText____________________________EmptyValue_SetsSuccessfully() public {
        string memory key = "key";
        string memory value = "";

        ensProfile.setText(key, value);

        assertEq(ensProfile.text(bytes32(0x0), key), value);
    }

    function test_026____grantRole__________________________AdminRole_GrantedSuccessfully() public {
        ensProfile.grantRole(ADMIN_ROLE, account2);
        assertTrue(ensProfile.hasRole(ADMIN_ROLE, account2));
    }

    function test_027____revokeRole_________________________AdminRole_RevokedSuccessfully() public {
        ensProfile.grantRole(ADMIN_ROLE, account2);
        ensProfile.revokeRole(ADMIN_ROLE, account2);
        assertFalse(ensProfile.hasRole(ADMIN_ROLE, account2));
    }

    function test_028____renounceRole_______________________AdminRole_RenouncedSuccessfully() public {
        ensProfile.grantRole(ADMIN_ROLE, account2);

        vm.stopPrank();
        vm.startPrank(account2);

        ensProfile.renounceRole(ADMIN_ROLE, account2);

        assertFalse(ensProfile.hasRole(ADMIN_ROLE, account2));
    }

    function test_029____grantRole__________________________UnauthorizedCaller_Reverts() public {
        vm.stopPrank();
        vm.startPrank(hacker);

        vm.expectRevert(
            abi.encodeWithSelector(
                AccessControlUnauthorizedAccount.selector,
                hacker,
                ensProfile.DEFAULT_ADMIN_ROLE()
            )
        );
        ensProfile.grantRole(ADMIN_ROLE, account2);
    }

    function test_030____setAddr____________________________NonAdmin_Reverts() public {
        vm.stopPrank();
        vm.startPrank(account2);

        vm.expectRevert(
            abi.encodeWithSelector(
                AccessControlUnauthorizedAccount.selector,
                account2,
                ADMIN_ROLE
            )
        );
        ensProfile.setAddr(account3);
    }

    function test_032____addExtension_______________________SameExtensionMultipleTimes() public {
        ensProfile.addExtension("eth.extension");
        ensProfile.addExtension("eth.extension");

        assertTrue(ensProfile.isExtensionActive("eth.extension"));
    }

    function test_033____addr_______________________________InvalidCoinType_ReturnsEmpty() public {
        uint256 invalidCoinType = 9999;
        bytes memory result = ensProfile.addr(bytes32(0x0), invalidCoinType);
        assertEq(result.length, 0);
    }

    function test_034____text_______________________________NullCharacterInKey() public {
        string memory key = string(abi.encodePacked("key", bytes1(0x00), "test"));
        string memory value = "value";

        ensProfile.setText(key, value);

        assertEq(ensProfile.text(bytes32(0x0), key), value);
    }

    function test_035____setText____________________________LongKeyAndValue() public {
        string memory key = new string(1024);
        string memory value = new string(2048);

        ensProfile.setText(key, value);
        assertEq(ensProfile.text(bytes32(0x0), key), value);
    }

    function test_036____resolve____________________________AddrSelector_NoData_ReturnsZeroAddress() public {
        bytes memory data = abi.encodeWithSelector(IAddrResolver.addr.selector, bytes32(0x0));
        bytes memory result = ensProfile.resolve("", data);

        address returnedAddr = abi.decode(result, (address));
        assertEq(returnedAddr, address(0));
    }

    function test_037____resolve____________________________AddrWithCoinTypeSelector_NoData_ReturnsEmpty() public {
        uint256 coinType = 1;
        bytes memory data = abi.encodeWithSelector(IAddressResolver.addr.selector, bytes32(0x0), coinType);
        bytes memory result = ensProfile.resolve("", data);
        bytes memory returnedData = abi.decode(result, (bytes));
        assertEq(returnedData.length, 0);
    }

    function test_038____resolve____________________________TextSelector_NoData_ReturnsEmptyString() public {
        string memory key = "nonexistent";
        bytes memory data = abi.encodeWithSelector(ITextResolver.text.selector, bytes32(0x0), key);
        bytes memory result = ensProfile.resolve("", data);
        string memory returnedValue = abi.decode(result, (string));
        assertEq(bytes(returnedValue).length, 0);
    }

    function test_039____addr_______________________________CoinType_LargeData() public {
        uint256 coinType = 1;
        bytes memory largeData = new bytes(1024);
        ensProfile.setAddr(coinType, largeData);
        bytes memory result = ensProfile.addr(bytes32(0x0), coinType);
        assertEq(result, largeData);
    }

    function test_040____setAddr____________________________CoinType_ZeroAddress() public {
        uint256 coinType = 1;
        bytes memory zeroAddressData = hex"0000000000000000000000000000000000000000";
        ensProfile.setAddr(coinType, zeroAddressData);
        bytes memory result = ensProfile.addr(bytes32(0x0), coinType);
        assertEq(result, zeroAddressData);
    }

    function test_041____grantRole__________________________SelfGranting_Reverts() public {
        vm.stopPrank();
        vm.startPrank(hacker);

        vm.expectRevert(
            abi.encodeWithSelector(
                AccessControlUnauthorizedAccount.selector,
                hacker,
                ensProfile.DEFAULT_ADMIN_ROLE()
            )
        );
        ensProfile.grantRole(ADMIN_ROLE, hacker);
    }

    function test_042____grantRole__________________________AlreadyGranted_NoEffect() public {
        ensProfile.grantRole(ADMIN_ROLE, account2);
        ensProfile.grantRole(ADMIN_ROLE, account2);
        assertTrue(ensProfile.hasRole(ADMIN_ROLE, account2));
    }

    function test_043____revokeRole_________________________NotGranted_NoEffect() public {
        ensProfile.revokeRole(ADMIN_ROLE, account2);
        assertFalse(ensProfile.hasRole(ADMIN_ROLE, account2));
    }

    function test_044____renounceRole_______________________NotGranted_NoEffect() public {
        vm.stopPrank();
        vm.startPrank(account2);
        ensProfile.renounceRole(ADMIN_ROLE, account2);
        assertFalse(ensProfile.hasRole(ADMIN_ROLE, account2));
    }

    function test_045____setAddr____________________________InvalidAddressLength() public {
        bytes memory invalidAddress = hex"123456";
        ensProfile.setAddr(60, invalidAddress);
        bytes memory result = ensProfile.addr(bytes32(0x0), 60);
        assertEq(result, invalidAddress);
    }

    function test_046____setText____________________________SpecialCharactersInKey() public {
        string memory key = unicode"特殊字符"; // Special characters
        string memory value = "value";
        ensProfile.setText(key, value);
        assertEq(ensProfile.text(bytes32(0x0), key), value);
    }

    function test_048____resolve____________________________CorrectData_AfterUpdating() public {
        ensProfile.setAddr(account2);
        bytes memory data = abi.encodeWithSelector(IAddrResolver.addr.selector, bytes32(0x0));
        bytes memory result = ensProfile.resolve("", data);
        address returnedAddr = abi.decode(result, (address));
        assertEq(returnedAddr, account2);

        ensProfile.setAddr(account3);
        result = ensProfile.resolve("", data);
        returnedAddr = abi.decode(result, (address));
        assertEq(returnedAddr, account3);
    }
}
