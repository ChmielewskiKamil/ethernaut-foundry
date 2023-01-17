// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./NaughtCoin.sol";

contract EchidnaNaughtCoin {
    NaughtCoin naughtCoin;

    constructor() {
        naughtCoin = new NaughtCoin(msg.sender);
    }

    function test_balance_of_player_should_equal_initial_supply() public {
        assert(
            naughtCoin.balanceOf(address(this)) == naughtCoin.INITIAL_SUPPLY()
        );
    }
}
