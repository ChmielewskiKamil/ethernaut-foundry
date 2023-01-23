# Ethernaut Level 15 - NaughtCoin

You can also read this [on my blog](https://wizzardhat.com/ethernaut-level-15-naughtcoin/) 😎

## Objectives
- Transfer tokens to another address skipping the lockout period.

## Contract Overview
The `NaughtCoin` contract is an ERC20 with the `transfer` function overriden with additional `lockTokens` modifier. 

## Finding the weak spots
At first glance everything in the `NaughtCoin` contract looks normal. The `lockTokens` modifiers has all the paths covered (they either end with the `_` or they revert), the `transfer` function seems to be overriden correctly. I am not entirely sure if the `ERC20` is constructed correctly. Usually the constructor takes the initial supply as an argument. 

The `INITIAL_SUPPLY` is a bit hard to read so it might be useful to separate digits with underscores. 

Let's define some invariants that need to be held in the contract and use Echidna to validate them. (I've added checkmarks after testing them)

1. Player token balance should be equal to the initial supply if current `block.timestamp < timelock`. 
2. Token transfer should fail if current `block.timestamp < timelock`. 
3. Token should be deployed (`address(token) != address(0)`) 
4. The approve function should never fail if the caller has sufficient token balance && it does not run out of gas. 
5. Token transfer via `transferFrom` should fail if `block.timestamp < timelock` and/or spender has enough `allowance`. 
6. Player should not be able to burn tokens before the `timelockPeriod`. 

I initially also wanted to test the property: "Should be able to allow only `<= balanceOf(owner)`" but it was quickly proven to be invalid. There is no built in mechanism in the `ERC20` token to check if you have enough tokens to do the approval. This is known as "allowance overrun". It is up to the developers to check for that. It is possible to approve more than you own. 

The last property "player should not burn tokens" is also invalid since the implementation of the `ERC20` used in this challenge does not have a public `burn` functionality. Burning by sending tokens to the `0` address won't work as well because of the `0` address checks everywhere in the Open Zeppelin ERC20 standard. It would be possible to burn tokens by sending them to a non-existent address tho. This would work if other properties (transfering tokens before `timeLock` period) would be violated so we can skip this one. 

[Feel free to look at how I implemented these properties in the `EchidnaTest` contract on my GitHub.](https://github.com/ChmielewskiKamil/ethernaut-foundry/tree/main/src/levels/15-NaughtCoin/crytic/EchidnaTest.sol) If you want to write your own properties I recommend you read [this article from John Regehr on how to write good assertions](https://blog.regehr.org/archives/1091). I got this from the [building secure contracts Echidna tutorial](https://github.com/crytic/building-secure-contracts/blob/master/program-analysis/echidna/assertion-checking.md). 

### How to test ERC20 token's properties with Echidna

The setup that I am using to write property tests with Echidna is explained in a great detail by [Justin Jacob in the Learn how to fuzz like a pro workshop - Part 3](https://youtu.be/n0RaKKVTGvA?t=4171)(coding starts at 1:09:31). This video is pure gold, just watch it. 

Let's start off with a simple property "Player token balance should be equal to the initial supply if current `block.timestamp < timelock`". We want to make sure that tokens are not moved/burned whatever before the `timelock` period.

Each property should follow this structure: 
```
// pre-conditions
// actions
// post-conditions
```

Pre-conditions define a situation in which the property will be tested. What is our pre-condition then? It's this: "the current time (`block.timestamp`) is smaller than the `timelock` period".

Actions are thing that are run between the conditions. They change the state of the contract and we want to test that the state is exactly what we expect it to be. In this property we won't have any actions. Later when we write different properties, Echidna will mix them together and will try to invalidate our assertions.

Post-conditions are the state-checks that we want to test after the action is performed. What is the post-conditions in our case? We want to make sure that the user token balance is equal to the initial supply at all times (in every situation described by the pre-conditions).

Let's write this property:
```solidity
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
```

Let's move on to the "Token transfer should fail if current `block.timestamp < timelock`" property. The pre-conditions are going to be similar to the ones before. We also need to save the starting token balance of our users (`player` and `bob`) so that we have something to refer to in the post-conditions. 

The action is going to be a simple `transfer`. Since we are using an external testing setup ([explained in the Echidna workshop](https://youtu.be/n0RaKKVTGvA?t=4171)), the call will be done via a `proxy` function of a User instance (user contract).

Look at the assertion below and try to guess why it is not a good assertion. Hint: It fails before the post conditions.

```solidity
	function test_player_should_not_transfer_tokens_before_timelock_period(
	uint256 amount
) public {
	// pre-conditions
	uint256 playerBalanceBefore = token.balanceOf(address(player));
	uint256 bobBalanceBefore = token.balanceOf(address(bob));
	uint256 currentTime = block.timestamp;

	if (currentTime < token.timeLock() && playerBalanceBefore > 0) {
		// action
		try
			player.proxy(
				address(token),
				abi.encodeWithSelector(
					token.transfer.selector,
					address(bob),
					amount
				)
			)
		{
			// transfer is expected to fail because currentTime < timelock
			assert(false);
		} catch {}
		// post-condition
		uint256 playerBalanceAfter = token.balanceOf(address(player));
		uint256 bobBalanceAfter = token.balanceOf(address(bob));
		assert(
			playerBalanceBefore == playerBalanceAfter &&
				bobBalanceBefore == bobBalanceAfter
		);
	}
}
```

The problem with this assertion is that it uses `try` & `catch`. The `try` & `catch` blocks are used to catch errors in external function calls. The `ERC20` used in this challenge does not revert on failure. It returns the status boolean. Because of that the call to the `token.transfer(uint256)` function will always "succeed" and the assertion `assert(false)` will be triggered every single time. We are ignoring the return value and hope for a revert but it does not happen. 

The way we can fix this issue is to remove the `try` & `catch` and replace it with a return value check. 

```solidity
// ... the rest of the function stays the same ...

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
		assert(false);
	}

	// post-condition
	uint256 playerBalanceAfter = token.balanceOf(address(player));
	uint256 bobBalanceAfter = token.balanceOf(address(bob));
	assert(playerBalanceBefore == playerBalanceAfter);
    assert(bobBalanceBefore == bobBalanceAfter);
}
```

Note, that now if the `transfer` succeeds, we will trigger an exception. This works but is far from perfect. We can do better than that. Right now when the `assert(false)` is triggered, our post-conditions won't be checked. The code will panic. Let's change that.

```solidity
// ... everything else stays the same ...

if (success1) {
	emit AssertionFailed(amount);
}

// ... everything else stays the same ...

```

We can emit a special event called `AssertionFailed`. It will let Echidna know that the assertion has been violated, but the rest of the function will still execute. This way, you can check the generated corpus and see if your post-conditions still hold or fail. 

There is one more thing that we can do to improve our test function. Since we know that the transfer with `amount >= playerBalance` will fail (we should check that with another property), we can constrain the `amount` of tokens Echidna will try to send. There are two ways in which we can achieve this:

```solidity
// 1st option
amount = amount % (playerBalanceBefore + 1);

// 2nd option 
amount = _between(amount, 0, playerBalanceBefore);

// where _between is a helper function in our Setup.sol
function _between(
	uint256 amount,
	uint256 low,
	uint256 high
) internal pure returns (uint256) {
	return (low + (amount % (high - low + 1)));
}
```

If you have watched [the video that I recommended you watch earlier](https://youtu.be/n0RaKKVTGvA?t=4171), you will understand what this between function does. 

Both of these options use the inner workings of the modulo operator. [This video by Golan Levin explains the concept well](https://youtu.be/r5Iy3v1co0A?t=159).  The `amount % balance` will bind the `amount` to values ranging from `0` up to the `balance` (Not included), that's why we are adding `+1`. [I've explained it in a greater detail in this pull request.](https://github.com/crytic/building-secure-contracts/pull/198)

In the case of my Ethernaut Foundry repository I can run Echidna with the following command:

```shell
echidna-test src/levels/15-NaughtCoin/crytic/EchidnaTest.sol --contract EchidnaTest --config src/levels/15-NaughtCoin/crytic/config.yaml
```

The properties hold. Let's move on.

Since the `NaughtCoin` contract inherits from the `ERC20` it has all of the `ERC20` methods available. Another way of transferring tokens is `transferFrom`. We want to make sure that the `transferFrom` does not bypass the `timelock` period.

The property in plain english: "Token transfer via `transferFrom` should fail if `block.timestamp < timelock` and/or spender has enough `allowance`. "

What are the pre-conditions? Same as before the current time has to be smaller than the `timelock` period. This time however we also have to provide the player with some allowance, so that he can transfer tokens. 

The action will be the `transferFrom` itself. 

In the post-conditions we are going to check that the token balance of the player did not decrease after the transfer. 

Before we test this property it would be wise to test that the `approve` function works correctly. Otherwise we would have a revert in our pre-conditions and our property would revert in the "actions" phase and our post-conditions wouldn't be checked. 

The property we want to test in plain english: "The approve called as a standalone function should never fail if the caller has sufficient token balance and the transaction does not run out of gas. "

When it comes to the gas part, we can skip it since we are not setting any gas limits to our transactions in the testing environment. The property is simple and it speaks for itself:

```solidity
function test_approve_should_never_fail_if_caller_has_enough_tokens(uint256 amountToApprove) public {
	// pre-conditions
	uint256 callerTokenBalance = token.balanceOf(address(player));
	if (callerTokenBalance >= amountToApprove) {
		// action
		(bool success1,) = player.proxy(
			address(token), abi.encodeWithSelector(token.approve.selector, address(bob), amountToApprove)
		);
		// post-condition
		assert(success1);
	}
}
```

In the pre-conditions we are checking that the caller has enough tokens to even make the approval. The post-conditions check that the approval should be always successful (in situations described by the pre-conditions).

Once we are sure that the `approve` works correctly we can get back to our `transferFrom` property. It will be almost identical to the `transfer` property described before.

```solidity
 function test_player_should_not_use_transfer_from_before_timelock_period(uint256 amount) public {
	// pre-conditions
	uint256 playerBalanceBefore = token.balanceOf(address(player));
	uint256 bobBalanceBefore = token.balanceOf(address(bob));
	uint256 currentTime = block.timestamp;
	amount = _between(amount, 0, token.totalSupply());

	if (currentTime < token.timeLock() && playerBalanceBefore > 0) {
		// player needs allowance to transfer tokens
		(bool success1,) =
			player.proxy(address(token), abi.encodeWithSelector(token.approve.selector, address(player), amount));
		require(success1);

		// action
		(bool success2,) = player.proxy(
			address(token),
			abi.encodeWithSelector(token.transferFrom.selector, address(player), address(bob), amount)
		);
		if (success2) {
			emit AssertionFailed(amount);
		}
		
		// post-condition
		uint256 playerBalanceAfter = token.balanceOf(address(player));
		uint256 bobBalanceAfter = token.balanceOf(address(bob));
		assert(playerBalanceBefore == playerBalanceAfter);
        assert(bobBalanceBefore == bobBalanceAfter);
	}
}
```

In the pre-conditions we are checking the standard stuff like: the current time has to be smaller than the `timelock` period and also making sure that the player has enough balance to approve and transfer tokens. 

The action part is identical to the one we defined before for the `transfer` function. If the `transferFrom` succeeds (we expect that it shouldn't) we will emit the `AssertionFailed` event. If we were to use a standard assertion, the post-condition checks wouldn't be tested. 

If we run Echidna now, an interesting thing is happening. 

![Level 15 echidna total supply is stil valid.](https://github.com/ChmielewskiKamil/ethernaut-foundry/blob/main/img/15-echidna-total-supply-stil-valid.png?raw=true)

The `AssertionFailed` event is emitted with the amount of `0`. It means that the `transferFrom` function succeeded. Because we have bounded the amount in our pre-conditions to be in the range from `0` up to `token.totalSupply` (included), `0` was the smallest `amount` that Echidna could find to invalidate the assertion. If we look at the generated corpus we see that our post-condition was violated:

```
 92 | *r  |   assert(playerBalanceBefore == playerBalanceAfter);
```

The property "player balance should be equal to the total supply" still holds. Why is that? Why Echidna wasn't able to use this information to invalidate this property? I will reorder properties and see if this changes anything. 

It doesn't.

By know we know that it is possible to change the balance of the user. Our post condition `playerBalanceBefore == playerBalanceAfter` was violated. It means that there is a way to make the player balance equal to `0`. Let's write a property to test that. 

```solidity
function test_player_balance_can_never_be_zero() public {
	// pre-conditions
	uint256 currentTime = block.timestamp;

	if (currentTime < token.timeLock()) {
		// post-conditions
		assert(token.balanceOf(address(player)) != 0);
	}
}
```

This property passes as well. That's weird. I think that we have to write a more general property that describes the functionality of the `transferFrom` function. Since we know that it is possible to use it to transfer tokens. Echidna will pick that up and check other properties against it.

The property: "There should be no free tokens created with transfer from." We want to be sure that the token supply stays constant and tokens flow from one user to the other. 

```solidity
function test_no_free_tokens_in_transfer_from(uint256 amount) public {
	// pre-conditions
	uint256 playerBalanceBefore = token.balanceOf(address(player));
	uint256 bobBalanceBefore = token.balanceOf(address(bob));

	if (amount <= playerBalanceBefore) {
		(bool success1,) =
			player.proxy(address(token), abi.encodeWithSelector(token.approve.selector, address(player), amount));
		require(success1);

		// actions
		(bool success2,) = player.proxy(
			address(token),
			abi.encodeWithSelector(token.transferFrom.selector, address(player), address(bob), amount)
		);
		require(success2);

		// post-conditions
		uint256 playerBalanceAfter = token.balanceOf(address(player));
		uint256 bobBalanceAfter = token.balanceOf(address(bob));

		assert(playerBalanceAfter == playerBalanceBefore - amount && bobBalanceAfter == bobBalanceBefore + amount);
	}
}
```

It does the trick. 

![Level 15 echidna total supply is violated.](https://github.com/ChmielewskiKamil/ethernaut-foundry/blob/main/img/15-echidna-supply-violated.png?raw=true)

This assertion is really counterintuitive to me. I wouldn't check for that since initially we did not know that `transferFrom` would even work (before `timelock` period). 

I guess the lesson learned is that we have to describe the system using properties. And the more properties we have the higher chance of finding a bug due to the compounding effect. Properties will be able to interact with each other for more creative ways of violating the assertions. In this case we have started with properties that made sense at the moment. Later we have discovered (by violating previous properties) that `transferFrom` behaves different than expected. A wise thing to do was to check that if it actually works, it has to work correctly (there are no free tokens). Because of that we discovered a way to violate different properties (reducing the balance to `0`).

## Potential attack scenario - hypothesis
*Eve is our player*

A malicious player wants to move funds from his address to the address of his friend Bob before the `timelock` period. 

Eve can transfer tokens to Bob by using the fact that the ERC20 `transferFrom` function is not `timeLock` protected. 

## Plan of the attack 
1. Eve will give herself the `allowance` to spend tokens.
	- She will use the `approve` function to do so. 
2. Eve will use the `transferFrom` function to transfer tokens to Bob.
3. This way her balance will be equal to `0`.

## Proof of Concept - hypothesis test ✅ 
The hypothesis has been proven to be true. You can see [the full PoC foundry unit test on my GitHub](https://github.com/ChmielewskiKamil/ethernaut-foundry/blob/main/test/15-NaughtCoin.t.sol). 

Here is a simplified version of the unit test:
```solidity
naughtCoinContract.approve(
	eve,
	naughtCoinContract.balanceOf(address(eve))
);

naughtCoinContract.transferFrom(
	address(eve),
	address(bob),
	naughtCoinContract.balanceOf(eve)
);
```

### Automated Testing and Verification

The following properties have been tested:

1. Player token balance should be equal to the initial supply. (❌  violated, if the 5th property is violated)
2. Token transfer should fail if current `block.timestamp < timelock`. ✅
3. Token should be deployed (`address(token) != address(0)`) ✅
4. The approve function should never fail if the caller has sufficient token balance && it does not run out of gas. ✅
5. Token transfer via `transferFrom` should fail if `block.timestamp < timelock` and/or spender has enough `allowance`. ❌
6. Player should not be able to burn tokens before the `timelockPeriod`. (❌  only because of the violation of the previous property, by sending tokens to non existing address, which effectively burns them)
7. There are no new tokens created because of the bad accounting (via `transferFrom`) ✅

## Recommendations
- Big numbers are hard to read. Consider separating them with underscores like so:
```
1000000 -> 1_000_000  
```

- Apply the `lockTokens` modifier to the `transferFrom` function as well:
```solidity
function transfer(address _to, uint256 _value)
	public
	override
	lockTokens
	returns (bool)
{
	super.transfer(_to, _value);
}
```
## References
- [John Regehr - Use of Assertions](https://blog.regehr.org/archives/1091)
- [ToB - Building secure contracts - Echidna](https://github.com/crytic/building-secure-contracts/blob/master/program-analysis/echidna/assertion-checking.md)
- [Learn how to fuzz like a pro: AMM Fuzzing - Justin Jacob](https://youtu.be/n0RaKKVTGvA?t=4171)
- You can also read this [on my blog](https://wizzardhat.com/ethernaut-level-15-naughtcoin/) 😎
