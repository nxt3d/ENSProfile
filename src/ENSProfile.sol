// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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

    /// @custom:storage-location erc7201:ens.resolver.storage
    struct ResolverStorage {
        mapping(uint256 => bytes) addresses;
        mapping(string => string) textRecords;
    }

    // bytes32 private constant RESOLVER_STORAGE_LOCATION = bytes32(uint256(keccak256(abi.encode(uint256(keccak256("ens.resolver.storage")) - 1))) & ~uint256(0xff));
    bytes32 private constant RESOLVER_STORAGE_LOCATION = 0x183a6125c38840424c4a85fa12bab2ab606c4b6d0e7cc73c0c06ba5300eab500;

    function _resolverStorage() private pure returns (ResolverStorage storage rs) {
        bytes32 position = RESOLVER_STORAGE_LOCATION;
        assembly {
            rs.slot := position
        }
    }

    /// @custom:storage-location erc7201:ens.resolver.hooks
    struct HooksStorage {
        mapping(address => bool) hooks;
    }

    // bytes32 private constant HOOKS_STORAGE_LOCATION = bytes32(uint256(keccak256(abi.encode(uint256(keccak256("ens.resolver.hooks")) - 1))) & ~uint256(0xff));
    bytes32 private constant HOOKS_STORAGE_LOCATION = 0x2cba3c35b83c5ff82316a6dca8bce1b1c99dc3952f8b59477e1ca6f0a14b1a00;

    function _hooksStorage() private pure returns (HooksStorage storage hs) {
        bytes32 position = HOOKS_STORAGE_LOCATION;
        assembly {
            hs.slot := position
        }
    }

    event HookAdded(address indexed hook);
    event HookRemoved(address indexed hook);

    function addr(bytes32) external view override(IAddrResolver) returns (address payable) {
        ResolverStorage storage rs = _resolverStorage();
        bytes memory a = rs.addresses[60]; // 60 is the coin type for ETH
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
        ResolverStorage storage rs = _resolverStorage();
        return rs.addresses[coinType];
    }

    function text(bytes32, string calldata key) external view override returns (string memory) {
        ResolverStorage storage rs = _resolverStorage();
        return rs.textRecords[key];
    }

    function resolve(bytes calldata, bytes calldata data) external view override returns (bytes memory) {
        bytes4 selector = bytes4(data[:4]);

        // Since mappings are not iterable, we cannot call hooks here.

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
        ResolverStorage storage rs = _resolverStorage();
        bytes memory a = abi.encodePacked(addr_);
        rs.addresses[60] = a; // 60 is the coin type for ETH
    }

    function setAddr(uint256 coinType, bytes memory a) external onlyRole(ADMIN_ROLE) {
        ResolverStorage storage rs = _resolverStorage();
        rs.addresses[coinType] = a;
    }

    function setText(string calldata key, string calldata value) external onlyRole(ADMIN_ROLE) {
        ResolverStorage storage rs = _resolverStorage();
        rs.textRecords[key] = value;
    }

    // Hook management functions
    function addHook(address hook) external onlyRole(ADMIN_ROLE) {
        require(hook != address(0), "Invalid hook address");
        HooksStorage storage hs = _hooksStorage();
        hs.hooks[hook] = true;
        emit HookAdded(hook);
    }

    function removeHook(address hook) external onlyRole(ADMIN_ROLE) {
        require(hook != address(0), "Invalid hook address");
        HooksStorage storage hs = _hooksStorage();
        hs.hooks[hook] = false;
        emit HookRemoved(hook);
    }

    function isHookActive(address hook) external view returns (bool) {
        HooksStorage storage hs = _hooksStorage();
        return hs.hooks[hook];
    }
}