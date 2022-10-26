// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract King {
    address payable king;
    uint public prize;
    address payable public owner;

    // @audit-ok
    constructor() public payable {
        owner = msg.sender;
        king = msg.sender;
        prize = msg.value;
    }

    receive() external payable {
        // @audit-issue violation of the Checks Effects Interactions pattern
        require(msg.value >= prize || msg.sender == owner);
        // @audit transfer is not recommended
        // because of the gas cost changes
        // @audit-issue violation of the CEI pattern
        // allows for reentrancies
        king.transfer(msg.value);
        king = msg.sender;
        prize = msg.value;
    }

    function _king() public view returns (address payable) {
        return king;
    }
}
