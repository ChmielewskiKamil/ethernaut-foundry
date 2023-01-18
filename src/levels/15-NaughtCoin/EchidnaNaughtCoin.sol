// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "src/levels/15-NaughtCoin/NaughtCoin.sol";

contract EchidnaNaughtCoin {
    NaughtCoin token;
    address echidna_caller = msg.sender;

    constructor() {
        token = NaughtCoin(echidna_caller);
    }

    function echidna_assert_true() public returns (bool) {
        assert(true);
    }
}
