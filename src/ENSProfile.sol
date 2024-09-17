// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

interface IAddrResolver {
    function addr(bytes32 node) external view returns (address);
    function addr(bytes32 node, uint256 coinType) external view returns (bytes memory);
}

interface ITextResolver {
    function text(bytes32 node, string calldata key) external view returns (string memory);
}

interface IExtendedResolver {
    function resolve(bytes calldata name, bytes calldata data) external view returns (bytes memory);
}

interface IResolverHook {
    function beforeResolve(bytes calldata name, bytes calldata data) external view;
}

contract MyResolver is ERC165, AccessControl, IAddrResolver, ITextResolver, IExtendedResolver {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    mapping(uint256 => bytes) private _addresses;
    mapping(string => string) private _textRecords;

    // Hooks storage as a mapping from address to bool
    mapping(address => bool) private _hooks;

    // Events for hook management
    event HookAdded(address indexed hook);
    event HookRemoved(address indexed hook);

    constructor() {
        // Assign the deployer as the default admin and admin role
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
    }

    // ERC-165 support
    function supportsInterface(bytes4 interfaceId) public view override(ERC165, AccessControl) returns (bool) {
        return
            interfaceId == type(IAddrResolver).interfaceId ||
            interfaceId == type(ITextResolver).interfaceId ||
            interfaceId == type(IExtendedResolver).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    // Address resolver for Ethereum address
    function addr(bytes32 /*node*/) external view override returns (address) {
        bytes memory a = _addresses[60]; // 60 is the coin type for ETH
        if (a.length == 20) {
            address addr_;
            assembly {
                addr_ := mload(add(a, 20))
            }
            return addr_;
        } else {
            return address(0);
        }
    }

    // Address resolver for other coin types
    function addr(bytes32 /*node*/, uint256 coinType) external view override returns (bytes memory) {
        return _addresses[coinType];
    }

    // Text resolver
    function text(bytes32 /*node*/, string calldata key) external view override returns (string memory) {
        return _textRecords[key];
    }

    // Extended resolver using the resolve method
    function resolve(bytes calldata /*name*/, bytes calldata data) external view override returns (bytes memory) {
        // Extract the function selector from the data
        bytes4 selector;
        assembly {
            selector := calldataload(data.offset)
        }

        // Dispatch the call based on the function selector
        if (selector == IAddrResolver.addr.selector) {
            // Decode the arguments for addr(bytes32)
            bytes32 node = abi.decode(data[4:], (bytes32));
            // Ignored node

            // Make a staticcall to the addr function
            (bool success, bytes memory result) = address(this).staticcall(
                abi.encodeWithSelector(IAddrResolver.addr.selector, node)
            );

            require(success, "addr call failed");
            return result;
        } else if (selector == this.addr.selector) {
            // Decode the arguments for addr(bytes32,uint256)
            (bytes32 node, uint256 coinType) = abi.decode(data[4:], (bytes32, uint256));
            // Ignored node

            // Make a staticcall to the addr function with coinType
            (bool success, bytes memory result) = address(this).staticcall(
                abi.encodeWithSelector(this.addr.selector, node, coinType)
            );

            require(success, "addr call with coinType failed");
            return result;
        } else if (selector == ITextResolver.text.selector) {
            // Decode the arguments for text(bytes32, string)
            (bytes32 node, string memory key) = abi.decode(data[4:], (bytes32, string));
            // Ignored node

            // Make a staticcall to the text function
            (bool success, bytes memory result) = address(this).staticcall(
                abi.encodeWithSelector(ITextResolver.text.selector, node, key)
            );

            require(success, "text call failed");
            return result;
        } else {
            revert("Unsupported function selector");
        }
    }

    // Function to set an address record (only admin role can set records)
    function setAddr(address addr_) external onlyRole(ADMIN_ROLE) {
        bytes memory a = abi.encodePacked(addr_);
        _addresses[60] = a; // 60 is the coin type for ETH
    }

    // Function to set an address record with coinType (only admin role can set records)
    function setAddr(uint256 coinType, bytes memory a) external onlyRole(ADMIN_ROLE) {
        _addresses[coinType] = a;
    }

    // Function to set a text record (only admin role can set records)
    function setText(string calldata key, string calldata value) external onlyRole(ADMIN_ROLE) {
        _textRecords[key] = value;
    }

    // Hook management functions
    function addHook(address hook) external onlyRole(ADMIN_ROLE) {
        require(hook != address(0), "Invalid hook address");
        _hooks[hook] = true;
        emit HookAdded(hook);
    }

    function removeHook(address hook) external onlyRole(ADMIN_ROLE) {
        require(hook != address(0), "Invalid hook address");
        _hooks[hook] = false;
        emit HookRemoved(hook);
    }

    // Function to check if a hook is active
    function isHookActive(address hook) external view returns (bool) {
        return _hooks[hook];
    }
}
