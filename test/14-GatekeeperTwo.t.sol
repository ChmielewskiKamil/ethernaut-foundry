// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// testing functionalities
import "forge-std/Test.sol";

// Ethernaut game components
import {Ethernaut} from "src/core/Ethernaut-08.sol";
import {GatekeeperTwoFactory, GatekeeperTwo} from "src/levels/14-GatekeeperTwo/GatekeeperTwoFactory.sol";

contract GatekeeperTwoTest is Test {
    /*//////////////////////////////////////////////////////////////
                            GAME INSTANCE SETUP
    //////////////////////////////////////////////////////////////*/

    Ethernaut ethernaut;

    /// @dev eve is the attacker
    address eve = makeNameForAddress("eve");

    function setUp() public {
        emit log_string("Setting up GatekeeperTwo level...");
        ethernaut = new Ethernaut();
    }

    /*//////////////////////////////////////////////////////////////
                LEVEL INSTANCE -> EXPLOIT -> SUBMISSION
    //////////////////////////////////////////////////////////////*/

    function test_GatekeeperTwoExploit() public {
        /*//////////////////////////////////////////////////////////////
                            LEVEL INSTANCE SETUP
        //////////////////////////////////////////////////////////////*/

        GatekeeperTwoFactory gatekeeperTwoFactory = new GatekeeperTwoFactory();

        ethernaut.registerLevel(gatekeeperTwoFactory);

        vm.startPrank(eve);
        address levelAddress = ethernaut.createLevelInstance(
            gatekeeperTwoFactory
        );

        GatekeeperTwo gatekeeperTwoContract = GatekeeperTwo(levelAddress);

        emit log_string("Starting the exploit...");
        emit log_named_address("Eve's address", eve);

        /*//////////////////////////////////////////////////////////////
                                LEVEL EXPLOIT
        //////////////////////////////////////////////////////////////*/

        /**
         * CODE GOES HERE
         */

        /*//////////////////////////////////////////////////////////////
                                LEVEL SUBMISSION
        //////////////////////////////////////////////////////////////*/

        bool challengeCompleted = ethernaut.submitLevelInstance(
            payable(levelAddress)
        );
        vm.stopPrank();
        assert(challengeCompleted);
    }

    /*//////////////////////////////////////////////////////////////
                            HELPER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * I've found this useful function
     * in github/twpony Ethernaut repo
     * @notice This function allows for creating labels (names) for addresses
     * which will improve readability in traces
     * @param name you pass the name like "alice" or "bob" and it will create
     * an address for that person
     */
    function makeNameForAddress(string memory name) public returns (address) {
        address addr = address(
            uint160(uint256(keccak256(abi.encodePacked(name))))
        );
        vm.label(addr, name);
        return addr;
    }
}
