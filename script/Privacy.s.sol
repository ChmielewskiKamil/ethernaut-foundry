// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "forge-std/Script.sol";

// Ethernaut game imports
import "src/core/Ethernaut.sol";
import "src/core/Level.sol";

// level 12 imports
import "src/levels/12-Privacy/Privacy.sol";
import "src/levels/12-Privacy/PrivacyFactory.sol";

contract MyScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY_ANVIL");
        vm.startBroadcast(deployerPrivateKey);

        // NFT nft = new NFT("NFT_tutorial", "TUT", "baseUri");
        Ethernaut ethernaut = new Ethernaut();

        PrivacyFactory privacyFactory = new PrivacyFactory();

        vm.stopBroadcast();
    }
}
