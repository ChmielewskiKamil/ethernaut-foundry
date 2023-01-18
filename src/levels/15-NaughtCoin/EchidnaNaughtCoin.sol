// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "src/levels/15-NaughtCoin/NaughtCoin.sol";

contract EchidnaNaughtCoin {
    NaughtCoin token;
    address echidna_caller = msg.sender;
    bool deployed;

    event InitialSupply(uint256 supply);

    function setUp() public {
        if (!deployed) {
            token = new NaughtCoin(echidna_caller);
            deployed = true;
        }
    }

    function assert_true() public {
        assert(true);
    }

    function token_is_deployed() public {
        if (!deployed) {
            assert(address(token) != echidna_caller);
        }
    }

    function initial_supply_should_be_set_properly() public {
        if (deployed) {
            emit InitialSupply(token.INITIAL_SUPPLY());
            assert(token.INITIAL_SUPPLY() == 1_000_000_000_000_000_000_000_000);
        }
    }

    function caller_balance_should_equal_initial_supply() public {
        if (deployed) {
            assert(token.balanceOf(echidna_caller) == token.INITIAL_SUPPLY());
        }
    }

    function token_transfer_always_revert_before_timelock(
        address to,
        uint256 amount
    ) public {
        if (deployed) {
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
}
