// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

interface Building {
    function isLastFloor(uint) external returns (bool);
}

contract ElevatorAttack is Building {
    function isLastFloor(uint256 _floor) external override returns (bool) {
        return false;
    }
}
