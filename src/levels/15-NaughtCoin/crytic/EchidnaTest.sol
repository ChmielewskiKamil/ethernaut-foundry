// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Setup} from "./Setup.sol";

contract EchidnaTest is Setup {
    event AssertionFailed(uint256);

    function test_token_is_deployed() public {
        assert(address(token) != address(0));
    }

    // @audit-info Property: Approve called as a standalone function should
    // never fail if:
    // - the caller has sufficient token balance
    // - the transaction does not run out of gas
    function test_approve_should_never_fail_if_caller_has_enough_tokens(
        uint256 amountToApprove
    ) public {
        // pre-conditions
        uint256 callerTokenBalance = token.balanceOf(address(player));
        if (callerTokenBalance >= amountToApprove) {
            // action
            (bool success1, ) = player.proxy(
                address(token),
                abi.encodeWithSelector(
                    token.approve.selector,
                    address(bob),
                    amountToApprove
                )
            );
            // post-condition
            assert(success1);
        }
    }

    function test_player_should_not_transfer_tokens_before_timelock_period(
        uint256 amount
    ) public {
        // pre-conditions
        uint256 playerBalanceBefore = token.balanceOf(address(player));
        uint256 bobBalanceBefore = token.balanceOf(address(bob));
        uint256 currentTime = block.timestamp;
        amount = _between(amount, 0, playerBalanceBefore);
        // amount = amount % (playerBalanceBefore + 1);
        if (currentTime < token.timeLock() && playerBalanceBefore > 0) {
            // action
            (bool success1, ) = player.proxy(
                address(token),
                abi.encodeWithSelector(
                    token.transfer.selector,
                    address(bob),
                    amount
                )
            );
            if (success1) {
                emit AssertionFailed(amount);
            }

            // post-condition
            uint256 playerBalanceAfter = token.balanceOf(address(player));
            uint256 bobBalanceAfter = token.balanceOf(address(bob));
            assert(playerBalanceBefore == playerBalanceAfter);
            assert(bobBalanceBefore == bobBalanceAfter);
        }
    }

    function test_player_should_not_use_transfer_from_before_timelock_period(
        uint256 amount
    ) public {
        // pre-conditions
        uint256 playerBalanceBefore = token.balanceOf(address(player));
        uint256 bobBalanceBefore = token.balanceOf(address(bob));
        uint256 currentTime = block.timestamp;
        amount = _between(amount, 0, playerBalanceBefore);
        // amount = amount % (playerBalanceBefore + 1);

        if (currentTime < token.timeLock() && playerBalanceBefore > 0) {
            // player needs allowance to transfer tokens
            (bool success1, ) = player.proxy(
                address(token),
                abi.encodeWithSelector(
                    token.approve.selector,
                    address(player),
                    amount
                )
            );
            require(success1);

            // action
            (bool success2, ) = player.proxy(
                address(token),
                abi.encodeWithSelector(
                    token.transferFrom.selector,
                    address(player),
                    address(bob),
                    amount
                )
            );
            if (success2) {
                emit AssertionFailed(amount);
            }
            // post-condition
            uint256 playerBalanceAfter = token.balanceOf(address(player));
            uint256 bobBalanceAfter = token.balanceOf(address(bob));
            // assert(playerBalanceBefore == playerBalanceAfter);
            // assert(bobBalanceBefore == bobBalanceAfter);
        }
    }

    function test_player_balance_should_be_equal_to_total_supply() public {
        // pre-conditions
        uint256 currentTime = block.timestamp;

        // actions
        // Whatever happens in between we want to make sure that ->
        // post-conditions are held

        if (currentTime < token.timeLock()) {
            // post-condition
            assert(token.balanceOf(address(player)) == token.INITIAL_SUPPLY());
        }
    }

    function test_player_balance_can_never_be_zero() public {
        // pre-conditions
        uint256 currentTime = block.timestamp;

        if (currentTime < token.timeLock()) {
            // post-conditions
            assert(token.balanceOf(address(player)) != 0);
        }
    }

    function test_no_free_tokens_in_transfer_from(uint256 amount) public {
        // pre-conditions
        uint256 playerBalanceBefore = token.balanceOf(address(player));
        uint256 bobBalanceBefore = token.balanceOf(address(bob));

        if (amount <= playerBalanceBefore) {
            (bool success1, ) = player.proxy(
                address(token),
                abi.encodeWithSelector(
                    token.approve.selector,
                    address(player),
                    amount
                )
            );
            require(success1);

            // actions
            (bool success2, ) = player.proxy(
                address(token),
                abi.encodeWithSelector(
                    token.transferFrom.selector,
                    address(player),
                    address(bob),
                    amount
                )
            );
            require(success2);

            // post-conditions
            uint256 playerBalanceAfter = token.balanceOf(address(player));
            uint256 bobBalanceAfter = token.balanceOf(address(bob));

            // assert(
            //     playerBalanceAfter == playerBalanceBefore - amount &&
            //         bobBalanceAfter == bobBalanceBefore + amount
            // );
        }
    }
    /* @audit-issue Property: This property is wrong. 
    There is no built in mechanism in ERC20 to check if the sender
    has more tokens than what he approves

    */
    // function should_not_approve_more_than_owns(uint256 amount) public {
    //     // pre-condition
    //     uint256 playerTokenBalance = token.balanceOf(address(player));
    //     if (amount > playerTokenBalance) {
    //         // action
    //         (bool success1, ) = player.proxy(
    //             address(token),
    //             abi.encodeWithSelector(
    //                 token.approve.selector,
    //                 address(bob),
    //                 amount
    //             )
    //         );

    //         assert(!success1);
    //     }
    // }
}
