// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "src/core/Level.sol";
import "./GatekeeperOne.sol";

contract GatekeeperOneFactory is Level {
    function createInstance(address _player) public payable override returns (address) {
        _player;
        GatekeeperOne instance = new GatekeeperOne();
        return address(instance);
    }

    function validateInstance(address payable _instance, address _player) public override returns (bool) {
        GatekeeperOne instance = GatekeeperOne(_instance);
        return instance.entrant() == _player;
    }
}
