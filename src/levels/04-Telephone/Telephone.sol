// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract Telephone {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    function changeOwner(address _owner) public {
        // @audit opposite of checking if the caller is an EOA
        // tx.origin == msg.sender
        if (tx.origin != msg.sender) {
            owner = _owner;
        }
    }
}
