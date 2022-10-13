// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

// testing functionalities
import "forge-std/Test.sol";

// Ethernaut game components
import "src/core/Ethernaut.sol";
import "src/levels/04-Telephone/TelephoneFactory.sol";
import "src/levels/04-Telephone/TelephoneExploit.sol";

contract TelephoneTest is Test {
    /*//////////////////////////////////////////////////////////////
                            GAME INSTANCE SETUP
    //////////////////////////////////////////////////////////////*/

    Ethernaut ethernaut;
    TelephoneExploit telephoneExploit;

    /// @dev eve is the attacker
    address eve = makeNameForAddress("eve");

    function setUp() public {
        emit log_string("Setting up Telephone level...");
        ethernaut = new Ethernaut();
    }

    /*//////////////////////////////////////////////////////////////
                LEVEL INSTANCE -> EXPLOIT -> SUBMISSION
    //////////////////////////////////////////////////////////////*/

    function test_TelephoneExploit() public {
        /*//////////////////////////////////////////////////////////////
                            LEVEL INSTANCE SETUP
        //////////////////////////////////////////////////////////////*/

        TelephoneFactory telephoneFactory = new TelephoneFactory();

        ethernaut.registerLevel(telephoneFactory);
        vm.startPrank(eve);

        address levelAddress = ethernaut.createLevelInstance(telephoneFactory);
        Telephone telephoneContract = Telephone(levelAddress);
        telephoneExploit = new TelephoneExploit(levelAddress);

        emit log_named_address(
            "Contract owner address: ",
            address(telephoneContract.owner())
        );
        emit log_named_address("Eve's address: ", address(eve));

        /*//////////////////////////////////////////////////////////////
                                LEVEL EXPLOIT
        //////////////////////////////////////////////////////////////*/
        emit log_string("Eve calls the attack function... 🧨");

        telephoneExploit.attack(eve);

        emit log_string("Ownership changed...");

        emit log_named_address(
            "New contract owner: ",
            address(telephoneContract.owner())
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
