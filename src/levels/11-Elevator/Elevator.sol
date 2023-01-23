// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

interface Building {
    function isLastFloor(uint256) external returns (bool);
}

contract Elevator {
    bool public top;
    uint256 public floor;

    function goTo(uint256 _floor) public {
        Building building = Building(msg.sender);
        /**
         * @audit to pass the level it is necessary to set the
         * boolean top -> true
         *
         * to achieve that we need to pass the following "if" check
         *
         * isLastFloor is called 2 times
         * 1. To get inside the if statement it needs to return false
         * 2. To set the "top" to true it needs to return true
         */

        if (!building.isLastFloor(_floor)) {
            floor = _floor;
            top = building.isLastFloor(floor);
        }
    }
}
