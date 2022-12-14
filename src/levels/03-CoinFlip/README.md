# Level 3 - CoinFlip

You can also read this
[on my blog](https://wizzardhat.com/ethernaut-level-3-coinflip/) 😎

## Objectives

- guess the correct outcome of the game 10 times in a row

## Contract Overview

`CoinFlip` contract is a blockchain game that lets users guess the outcome of
flipping a coin. The outcome can be either `true` or `false`.

- Users can guess the number by calling `flip()` function and passing their
  guess as an argument to the `_guess` parameter.
- The `flip()` function uses on-chain randomness via `blockhash` and
  `block.number`.
- The goal of the game is to get the most consecutive wins.

## How does the game calculate the outcome?

I've tried to dig a little deeper into the `coinFlip` logic. I wanted to
understand how it calculates the boolean value `side` to be exact. Along the
way, I've found a possible bug in Foundry...

The `flip()` function calculates the `blockValue` by taking the hash of the
previous block and parsing it to `uint256`. Then it divides the result by a
large decimal number, which is stored under the variable `FACTOR`.

> Please recall that in Solidity if the outcome of the division of two numbers
> is a floating point number, the result is automatically rounded to 0. Example:
> `3/4 = 0`

The `coinFlip` is based on this rounding property. If the `blockValue` is
smaller than the `FACTOR` the outcome will be smaller than `1` and it will be
rounded to `0`. On the other hand, if it is bigger, it will be rounded to `1`.
There is one problem though. What would happen if `blockValue` would be two
times bigger than the `FACTOR`?

I tinkered a bit and created this bash script to mimic the `flip()` function
functionality. It mainly uses `cast` from Foundry.

```shell
#!/bin/zsh
coinFlip() {
	# get the latest block number
	blockNumber=$(cast block latest number)
	# get the hash of the previous block
	blockhash=$(cast block $(($blockNumber - 1)) hash)
	echo ${blockhash}
	FACTOR=57896044618658097711785492504343953926634992332820282019728792003956564819968

	# calculate block value the same way as a flip() function
	blockValue=$(cast --to-base --base-in hex ${blockhash} dec)
	echo ${blockValue}

	# calculate the game outcome -> floating point number
	gameOutcome=$(bc <<< "scale=3; $blockValue / $FACTOR")
	echo ${gameOutcome}
}
# call coinFlip
coinFlip
```

This is where things started getting weird. My script always returned values
smaller than `1`. This would mean that the outcome would be rounded to `0` in
the `flip()` function and you would never win. This is the sample output from
the program:

![Incorrect output from the CoinFlip.sh](https://github.com/ChmielewskiKamil/ethernaut-foundry/blob/main/img/CoinFlipScript-incorrect-output.png?raw=true)

- The first line is the hash of the previous block
- The second line is the calculated `blockValue`
- The third line is the game outcome

This looks fine at first but if you take that hex number and put it into any
online hex-to-decimal converter
[like this one](https://codebeautify.org/decimal-hex-converter) or
[this one](https://www.rapidtables.com/convert/number/hex-to-decimal.html), you
will get a completely different decimal value!

![Example conversion using online hex to dec converter](https://github.com/ChmielewskiKamil/ethernaut-foundry/blob/main/img/CoinFlip-hex-to-decimal-converter.png?raw=true)

This is not our number. It turns out that the `cast --to-base` function has some
problems with numbers raised to the power of `77` that are close to the
`max_uin256` value. If you want to read a more detailed explanation of this
problem, please refer to the issue that I've submitted to the Foundry repo
[here](https://github.com/foundry-rs/foundry/issues/3432).

If we hardcode the proper values into the script, we get the following result.

![Correct output fron the FlipCoin script using hardcoded values](https://github.com/ChmielewskiKamil/ethernaut-foundry/blob/main/img/CoinFlipScript-hardcoded-values-proper-result.png?raw=true)

`1.754` will be rounded to `1` and everything will work fine.

If you have any thoughts about this issue please contact me on
[Twitter](https://twitter.com/kamilchmielu). I would love to hear from you.

### UPDATE 05.10.2022

As of today, my issue is resolved. The script will return the proper result.
Wrong conversion has been fixed in yesterday's nightly release of Foundry.

Answering my previous question: what if the `blockValue` would be double the
`FACTOR`? It turns out that the factor is big enough that the `blockValue` would
have to be bigger than the `max_uint256` value. So it is not possible.

We can continue with the report...

## Finding the weak spots

`Flip()` function uses
[Weak PRNG](https://github.com/crytic/slither/wiki/Detector-Documentation#weak-prng).
To some extent, this can be abused by the miners by reordering blocks.

This can also be abused by the attackers who have access to the source code of
the smart contract and can reverse the game logic and calculate the winning
condition in advance.

There is also no check inside of the `flip()` function to determine whether the
caller is an EOA or a smart contract. This wouldn't mitigate the issue
completely but would make it harder to attack the contract.

## Potential attack scenario - hypothesis

_Eve is our attacker_

Eve can create a malicious contract that will contain an `attack` function that
calculates the outcome of the game in advance. Eve can call this function each
block and score 10 consecutive wins easily.

## Plan of the attack

1. Eve calls the `attack` function.
2. The `attack` function calculates the outcome of the game -> boolean value
   `side`.
3. The `attack` function calls the `flip()` function inside the `CoinFlip`
   contract.
   - It passes the calculated `side` value as an argument to the `_guess`
     parameter of the `flip()` function.
4. Eve will repeat the attack in 10 consecutive blocks.

## Proof of Concept - hypothesis test ✅

Here is a simplified version of the unit test exploiting the vulnerability Full
version
([here](https://github.com/ChmielewskiKamil/ethernaut-foundry/blob/main/src/levels/03-CoinFlip/CoinFlipExploit.sol))

```solidity
/*
* we are going to simulate Eve calling the `attack` function
* 10 times via for loop
* @param blockNumber is the number of the current block
* Eve would be waiting for the next block to call the `attack`
* blockNumber gets incremented
* Eve repeats the attack
*
* we are using vm.roll() to create the next block
*/
for (uint blockNumber = 1; blockNumber <= 10; blockNumber++) {
	vm.roll(blockNumber);

	coinFlipExploit.coinFlipAttack();
);
```

Here are the logs from the exploit:

![Image of the logs of the CoinFlip exploit](https://github.com/ChmielewskiKamil/ethernaut-foundry/blob/main/img/CoinFlipExploit-logs.png?raw=true)

## Recommendations

- `CoinFlip` contract can be easily exploited by abusing the Weak PRNG. This can
  be used both by the miners and the potential malicious users.
  - The use of Chainlink VRF or RANDAO is recommended for generating randomness.
- The `flip()` function does not check if the caller is a contract. Such a check
  would prevent attacks like the one presented in the Proof of Concept. An
  example of such validation would be wrapping the logic of the `flip()`
  function in the `if / else` statement like the one shown below:

```solidity
function flip(bool _guess) public returns (bool) {
	if (msg.sender == tx.origin) {
		/*
		* LOGIC HERE
		*/
	}
	else {
		revert("Caller cannot be a contract!");
	}
}
```

- This however would not solve the problem completely. The attacker could still
  calculate the outcome of the game externally and call the `flip()` function
  manually or automate the whole process via a `bash` script similar to the one
  shown before.
