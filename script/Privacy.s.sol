// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "forge-std/Script.sol";
// test is needed for emitting events
import "forge-std/Test.sol";

// Ethernaut game imports
import "src/core/Ethernaut.sol";
import "src/core/Level.sol";

// level 12 imports
import "src/levels/12-Privacy/Privacy.sol";
import "src/levels/12-Privacy/PrivacyFactory.sol";

contract Deployment is Script, Test {
    // to run the script use:
    // forge script script/Privacy.s.sol:Deployment --fork-url http://localhost:8545 --broadcast
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("ANVIL_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // GAME INSTANCE SETUP //
        Ethernaut ethernaut = new Ethernaut();

        // LEVEL INSTANCE SETUP //
        PrivacyFactory privacyFactory = new PrivacyFactory();
        ethernaut.registerLevel(privacyFactory);

        address levelAddress = ethernaut.createLevelInstance(privacyFactory);
        Privacy privacyContract = Privacy(levelAddress);

        // Level address will appear in the logs section
        // after running the script
        emit log_named_address("Level address: ", levelAddress);

        vm.stopBroadcast();
    }
}
