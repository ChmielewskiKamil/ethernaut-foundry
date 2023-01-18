// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Setup} from "./Setup.sol";

contract EchidnaTest is Setup {
    function test_token_is_deployed() public {
        assert(address(token) != address(0));
    }

    function player_balance_should_be_equal_to_total_supply() public {
        assert(token.balanceOf(address(player)) == token.INITIAL_SUPPLY());
    }
}
