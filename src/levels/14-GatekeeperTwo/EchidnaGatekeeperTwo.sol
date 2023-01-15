// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {GatekeeperTwo} from "./GatekeeperTwo.sol";

contract EchidnaGatekeeperTwo {
    GatekeeperTwo gatekeeperTwo =
        GatekeeperTwo(0x903ef7B0c35291f89407903270FeA611C85f515c);

    function test_if_can_pass_the_gate() public view {
        // assert(gatekeeperTwo.entrant() == address(0));
    }
}
