// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "src/levels/15-NaughtCoin/NaughtCoin.sol";

contract EchidnaNaughtCoin {
    NaughtCoin token;
    address echidna_caller = msg.sender;

    constructor() {
        token = NaughtCoin(echidna_caller);
    }

    function assert_true() public {
        assert(true);
    }

    function token_is_deployed() public {
        assert(address(token) != address(0));
    }

    function caller_balance_should_equal_initial_supply() public {
        // setup
        uint256 callerBalanceInitial = token.balanceOf(echidna_caller);

        // property
        assert(callerBalanceInitial == token.balanceOf(echidna_caller));
    }

    function token_transfer_always_revert_before_timelock(
        address to,
        uint256 amount
    ) public {
        // pre-conditions
        uint256 currentTime = block.timestamp;
        if (currentTime < token.timeLock()) {
            (bool success, ) = address(token).call(
                abi.encodeWithSignature(
                    "transfer(address, uint256)",
                    to,
                    amount
                )
            );
            // property
            assert(!success);
        }
    }
}
