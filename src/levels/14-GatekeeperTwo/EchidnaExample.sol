// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EchidnaExample {
    address public entrant;

    modifier gateThree(bytes8 _gateKey) {
        require(
            uint64(bytes8(keccak256(abi.encodePacked(msg.sender)))) ^
                uint64(_gateKey) ==
                type(uint64).max
        );
        _;
    }

    function enter(bytes8 _gateKey) public gateThree(_gateKey) returns (bool) {
        entrant = tx.origin;
        return true;
    }
}

contract TestEchidnaExample is EchidnaExample {
    address echidna_caller = msg.sender;

    function test_if_can_pass_the_gate(bytes8 gateKey) public {
        assert(entrant == address(0));
    }
}
