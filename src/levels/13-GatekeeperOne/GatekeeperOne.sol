// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "openzeppelin-contracts/math/SafeMath.sol";

contract GatekeeperOne {
    using SafeMath for uint256;
    address public entrant;

    // @audit call from a contract will pass the check
    modifier gateOne() {
        require(msg.sender != tx.origin, "Gate one fail");
        _;
    }

    // @audit modifiers are applied before the function logic is executed
    // it means that the gasleft() will return the amount of gas
    // that was passed in the external function call
    // probably supplying 8191 units of gas will do the trick
    // or any number * 8191
    modifier gateTwo() {
        require(gasleft().mod(8191) == 0, "Gate two fail");
        _;
    }

    modifier gateThree(bytes8 _gateKey) {
        require(
            uint32(uint64(_gateKey)) == uint16(uint64(_gateKey)),
            "GatekeeperOne: invalid gateThree part one"
        );
        require(
            uint32(uint64(_gateKey)) != uint64(_gateKey),
            "GatekeeperOne: invalid gateThree part two"
        );
        require(
            // @audit I guess we need to go backwards from uint16(tx.origin)
            // from this equation we will derive the _gateKey
            // and everything else will probably match
            uint32(uint64(_gateKey)) == uint16(tx.origin),
            "GatekeeperOne: invalid gateThree part three"
        );
        _;
    }

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
