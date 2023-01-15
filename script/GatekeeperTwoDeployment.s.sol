// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
// testing functionalities
import "forge-std/Test.sol";

// Ethernaut game components
import {Ethernaut} from "src/core/Ethernaut-08.sol";
import {GatekeeperTwoFactory, GatekeeperTwo} from "src/levels/14-GatekeeperTwo/GatekeeperTwoFactory.sol";

contract GatekeeperTwoDeployment is Script, Test {
    // to run the script use:
    // forge script script/GatekeeperTwoDeployment.s.sol:GatekeeperTwoDeployment --fork-url http://127.0.0.1:8546 --broadcast
    function run() external {
        uint256 deployerPrivateKey = 0x5d862464fe9303452126c8bc94274b8c5f9874cbd219789b3eb2128075a76f72;
        vm.startBroadcast(deployerPrivateKey);

        // GAME INSTANCE SETUP //
        Ethernaut ethernaut = new Ethernaut();

        // LEVEL INSTANCE SETUP //
        GatekeeperTwoFactory gatekeeperTwoFactory = new GatekeeperTwoFactory();
        ethernaut.registerLevel(gatekeeperTwoFactory);

        address levelAddress = ethernaut.createLevelInstance(
            gatekeeperTwoFactory
        );
        GatekeeperTwo gatekeeperTwoContract = GatekeeperTwo(levelAddress);

        // Level address will appear in the logs section
        // after running the script
        emit log_named_address("Level address: ", levelAddress);

        vm.stopBroadcast();
    }
}
