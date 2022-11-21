// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// @audit - There is no SafeMath as in Gatekeeper One -> Sol version ^0.8.0
contract GatekeeperTwo {
    address public entrant;

    // @audit-ok - this is the exact same modifier as in the previous challenge
    modifier gateOne() {
        require(msg.sender != tx.origin);
        _;
    }

    /*
     * @todo - does extcodesize return the size of the code at the given address?
     * @todo - is caller() some assembly specific keyword/function?
     * does it check for tx.origin or msg.sender or smth else?
     * @todo - is the syntax x := correct?
     * what does it do?
     */
    modifier gateTwo() {
        uint x;
        // @audit - there is no type safety in assembly
        // is this safe?
        assembly {
            x := extcodesize(caller())
        }
        require(x == 0);
        _;
    }
    /*
     * @todo - what does encodePacked(msg.sender) looks like?
     * encodePacked leaves no padding so... ?
     *
     * @audit - is the order of operations correct?
     * Is it (uint64 ^ uint64) == type(uint64)?
     * or
     * Is it (uint64) ^ (uint64 == type(uint64))?
     *
     * @todo - is max(uint65) == 2^64 - 1?
     */
    modifier gateThree(bytes8 _gateKey) {
        require(
            uint64(bytes8(keccak256(abi.encodePacked(msg.sender)))) ^
                uint64(_gateKey) ==
                type(uint64).max
        );
        _;
    }

    // @audit-ok - this is the exact same function as in the previous challenge
    function enter(bytes8 _gateKey)
        public
        gateOne
        gateTwo
        gateThree(_gateKey)
        returns (bool)
    {
        entrant = tx.origin;
        return true;
    }
}
