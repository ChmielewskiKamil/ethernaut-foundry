// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "src/levels/11-Elevator/Elevator.sol";

contract ElevatorAttack is Building {
    function isLastFloor(uint256 _floor) external override returns (bool) {
        return false;
    }
}
