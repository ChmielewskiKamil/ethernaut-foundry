// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "src/levels/15-NaughtCoin/NaughtCoin.sol";

contract EchidnaNaughtCoin {
    NaughtCoin token;
    address echidna_caller = msg.sender;
    bool deployed;

    event InitialSupply(uint256 supply);
    event Time(uint256 time);

    function setUp() public {
        if (!deployed) {
            token = new NaughtCoin(echidna_caller);
            deployed = true;
        }
    }

    function token_is_deployed() public {
        require(deployed);
        assert(address(token) != address(0));
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

    // @audit-info Property: Player should not be able to transfer tokens
    // before the timelock period
    function token_transfer_always_revert_before_timelock_period(
        address to,
        uint256 amount
    ) public {
        // setup
        uint256 currentTime = block.timestamp;
        // pre-conditions
        if (deployed && currentTime < token.timeLock()) {
            amount = _between(amount, 1, token.INITIAL_SUPPLY());
            // actions
            try token.transfer(to, amount) {
                emit Time(currentTime);
                emit Time(token.timeLock());
                assert(false);
            } catch {}
            // post-conditions
            assert(token.balanceOf(echidna_caller) == token.INITIAL_SUPPLY());
        }
    }

    // @audit-info Property: It should not be possible to move funds from
    // the timelocked balance to a different address via transferFrom
    function transfer_from_always_revert_before_timelock_period() public {
        // pre-conditions
        // actions
        // post conditions
    }

    // @audit-info Helper function to increase allowance for other properties
    function _increaseAllowance(address spender, uint256 addedAmount)
        internal
        returns (bool)
    {
        bool success = token.increaseAllowance(spender, addedAmount);
        require(success);
    }

    function _between(
        uint256 amount,
        uint256 low,
        uint256 max
    ) internal pure returns (uint256) {
        return (low + (amount % (max - low + 1)));
    }
}
