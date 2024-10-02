// a dummy ERC20 token contract

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.26;

contract DummyERC20Token {
   
    function getVotes(address account) public view virtual returns (uint256) {
        return 130104422044868748111849;
    } 
}

