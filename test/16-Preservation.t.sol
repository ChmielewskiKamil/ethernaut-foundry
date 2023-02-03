// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

// Ethernaut game components
import {Ethernaut} from "src/core/Ethernaut-08.sol";
import {PreservationFactory, Preservation} from "src/levels/16-Preservation/PreservationFactory.sol";
import {LibraryAttack} from "src/levels/16-Preservation/LibraryAttack.sol";

contract PreservationTest is Test {
    /*//////////////////////////////////////////////////////////////
                            GAME INSTANCE SETUP
    //////////////////////////////////////////////////////////////*/

    Ethernaut ethernaut;

    /// @dev eve is the attacker
    address eve = makeNameForAddress("eve");
    address bob = makeNameForAddress("bob");

    function setUp() public {
        emit log_string("Setting up Preservation level...");
        ethernaut = new Ethernaut();
    }

    /*//////////////////////////////////////////////////////////////
                LEVEL INSTANCE -> EXPLOIT -> SUBMISSION
    //////////////////////////////////////////////////////////////*/

    function test_PreservationExploit() public {
        /*//////////////////////////////////////////////////////////////
                            LEVEL INSTANCE SETUP
        //////////////////////////////////////////////////////////////*/

        PreservationFactory preservationFactory = new PreservationFactory();

        ethernaut.registerLevel(preservationFactory);

        vm.startPrank(eve);
        address levelAddress = ethernaut.createLevelInstance(
            preservationFactory
        );

        Preservation preservationContract = Preservation(levelAddress);

        emit log_string("Starting the exploit...");
        emit log_named_address("Eve's address", eve);

        /*//////////////////////////////////////////////////////////////
                                LEVEL EXPLOIT
        //////////////////////////////////////////////////////////////*/
        LibraryAttack attackContract = new LibraryAttack(levelAddress);
        attackContract.attack();
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
