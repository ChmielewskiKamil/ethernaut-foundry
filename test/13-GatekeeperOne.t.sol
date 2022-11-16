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
        vm.startPrank(eve);

        address levelAddress = ethernaut.createLevelInstance(
            gatekeeperOneFactory
        );
        GatekeeperOne gatekeeperOneContract = GatekeeperOne(levelAddress);

        emit log_string("Starting the exploit... 🧨");
        emit log_named_address("Eve's address", eve);
        uint16 eveAddrSliced = uint16(eve);
        emit log_named_uint("Eve's address sliced", eveAddrSliced);

        /*//////////////////////////////////////////////////////////////
                                LEVEL EXPLOIT
        //////////////////////////////////////////////////////////////*/

        GatekeeperOneAttack gatekeeperOneAttack = new GatekeeperOneAttack(
            address(gatekeeperOneContract)
        );

        gatekeeperOneAttack.attack();
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
