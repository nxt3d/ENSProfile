// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "openzeppelin/contracts/utils/introspection/ERC165.sol";
import "openzeppelin/contracts/access/AccessControl.sol";

// Import ENS interfaces
import "ens-contracts/resolvers/profiles/IAddressResolver.sol";
import "ens-contracts/resolvers/profiles/IAddrResolver.sol";
import "ens-contracts/resolvers/profiles/ITextResolver.sol";
import "ens-contracts/resolvers/profiles/IExtendedResolver.sol";

contract ENSProfile is ERC165, AccessControl, IAddrResolver, IAddressResolver, ITextResolver, IExtendedResolver {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
    }

    function supportsInterface(bytes4 interfaceID) public view override(ERC165, AccessControl) returns (bool) {
        return
            interfaceID == type(IAddrResolver).interfaceId ||
            interfaceID == type(IAddressResolver).interfaceId ||
            interfaceID == type(ITextResolver).interfaceId ||
            interfaceID == type(IExtendedResolver).interfaceId ||
            super.supportsInterface(interfaceID);
    }

    mapping(uint256 => bytes) addresses;
    mapping(string => string) textRecords;
    mapping(string extension => bool) extensions;


    event ExtensionAdded(string indexed extension);
    event ExtensionRemoved(string indexed extension);

    function addr(bytes32) external view override(IAddrResolver) returns (address payable) {
        bytes memory a = addresses[60]; // 60 is the coin type for ETH
        if (a.length == 20) {
            address payable addr_;
            assembly {
                addr_ := mload(add(a, 20))
            }
            return addr_;
        } else {
            return payable(address(0));
        }
    }

    function addr(bytes32, uint256 coinType) external view override(IAddressResolver) returns (bytes memory) {
        return addresses[coinType];
    }

    function text(bytes32, string calldata key) external view override returns (string memory) {
        return textRecords[key];
    }

    function resolve(bytes calldata, bytes calldata data) external view override returns (bytes memory) {
        bytes4 selector = bytes4(data[:4]);

        if (selector == IAddrResolver.addr.selector) {
            (bool success, bytes memory result) = address(this).staticcall(data);
            require(success, "addr(bytes32) call failed");
            return result;
        } else if (selector == IAddressResolver.addr.selector) {
            (bool success, bytes memory result) = address(this).staticcall(data);
            require(success, "addr(bytes32,uint256) call failed");
            return result;
        } else if (selector == ITextResolver.text.selector) {
            (bool success, bytes memory result) = address(this).staticcall(data);
            require(success, "text call failed");
            return result;
        } else {
            revert("Unsupported function selector");
        }
    }

    function setAddr(address addr_) external onlyRole(ADMIN_ROLE) {
        bytes memory a = abi.encodePacked(addr_);
        addresses[60] = a; // 60 is the coin type for ETH
        emit AddrChanged(bytes32(0x0), addr_); // Emitting AddrChanged event
    }

    function setAddr(uint256 coinType, bytes memory a) external onlyRole(ADMIN_ROLE) {
        addresses[coinType] = a;
        emit AddressChanged(bytes32(0x0), coinType, a); // Emitting AddressChanged event
    }

    function setText(string calldata key, string calldata value) external onlyRole(ADMIN_ROLE) {
        textRecords[key] = value;
        emit TextChanged(bytes32(0x0), key, key, value); // Emitting TextChanged event
    }

    // Extension management functions
    function addExtension(string memory extension) external onlyRole(ADMIN_ROLE) {
        extensions[extension] = true;
        emit ExtensionAdded(extension);
    }

    function removeExtension(string memory extension) external onlyRole(ADMIN_ROLE) {
        extensions[extension] = false;
        emit ExtensionRemoved(extension);
    }

    function isExtensionActive(string memory extension) external view returns (bool) {
        return extensions[extension];
    }
}
