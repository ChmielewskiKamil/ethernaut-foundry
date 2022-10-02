// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

// testing functionalities
import "forge-std/Test.sol";

// Ethernaut game components
import "src/levels/03-CoinFlip/CoinFlipFactory.sol";
import "src/core/Ethernaut.sol";

contract CoinFlipTest is Test {
    /*//////////////////////////////////////////////////////////////
                            GAME INSTANCE SETUP
    //////////////////////////////////////////////////////////////*/

    Ethernaut ethernaut;

    /// @dev eve is the attacker
    address eve = makeNameForAddress("eve");

    function setUp() public {
        emit log_string("Setting up CoinFlip level...");
        ethernaut = new Ethernaut();
        // We need to give eve some funds to attack the contract
        vm.deal(eve, 10 wei);
    }

    /*//////////////////////////////////////////////////////////////
                LEVEL INSTANCE -> EXPLOIT -> SUBMISSION
    //////////////////////////////////////////////////////////////*/

    function test_CoinFlipExploit() public {
        /*//////////////////////////////////////////////////////////////
                            LEVEL INSTANCE SETUP
        //////////////////////////////////////////////////////////////*/

        CoinFlipFactory coinFlipFactory = new CoinFlipFactory();

        ethernaut.registerLevel(coinFlipFactory);
        vm.startPrank(eve);

        address levelAddress = ethernaut.createLevelInstance(coinFlipFactory);
        CoinFlip coinFlipContract = CoinFlip(payable(levelAddress));
        vm.deal(address(coinFlipContract), 1 ether);

        emit log_named_address(
            "Address of the exploit contract: ",
            address(this)
        );
        emit log_named_address("Eve's address: ", address(eve));

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
