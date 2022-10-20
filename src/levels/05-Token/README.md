# Ethernaut Level 5 - Token

## Objectives

- You are given 20 tokens. Use them to gain additional tokens.

## Contract Overview

The `Token` contract is a simplified version of the ERC20 standard. It has 2 out
of 6 core ERC20 functions (`transfer()` and `balanceOf()`). It does not have the
mechanism of approval/spending of someone else's tokens. It also does not emit
`Transfer` and `Approval` events, which are necessary for the ERC20
specification. The `Token` contract lacks important safety checks to prevent
some of the most common ERC20 vulnerabilities.

Other than that, the `Token` contract is functioning almost the same as the
ERC20.

## Finding the weak spots

### Token.sol

- The `transfer()` function is vulnerable to integer overflow. The
  `balances[msg.sender] - _value >= 0` is a bad way of checking the ability of
  the sender to transfer tokens.
  - The `Token` contract uses the `^0.6.0` Solidity version, which does not have
    built-in over/underflow checks. The contract also does not use the
    `SafeMath` library.
  - A better way of making such a check would be
    `balances[msg.sender] >= _value`. It would completely negate the need of
    using arithmetic operations. Such checks are used in the current
    implementation of the OpenZeppelin ERC20 token standard.
- For the same reason as above the `balances[msg.sender] -= _value;` will
  underflow and wrap to the other side of the uint256 range. The user will be in
  a possession of a very high amount of tokens.
- The `transfer()` function does not revert on failure. Instead, it returns the
  boolean value (default - `false`), which needs to be taken care of on the
  caller's end. If the user is not expecting it, this can lead to undefined
  behaviour.
- The `transfer()` function does not check if the `_to` address is the `0`
  address. This allows for accidental (or on-purpose) token burning.
- I am not sure about this one, but I am curious whether
  `balances[_to] += _value;` can also overflow. This may lead to some
  interesting behaviour where the potential attacker uses `transfer()` to send
  tokens to himself and:
  1.  underflows `balances[msg.sender] -= _value;` which gives him a huge amount
      of tokens
  2.  but later overflows his modified balance `balances[_to] += _value`, which
      effectively negates the exploit

I might be missing something but I am going to test this case out.

### TokenFactory.sol

The `TokenFactory` contract does not use underscores to represent large numbers
(total supply in this case). This may lead to potential mistakes and typos.

## Potential attack scenario - hypothesis

_Eve is our attacker_

Given the goal of gaining additional tokens, Eve can exploit arithmetic
underflow to increase her balance to any value via the `transfer()` function.

In the standard ERC20, the sum of all balances is capped by `totalSupply` and
the sum is kept constant by adding and subtracting tokens from balances inside
the `transfer()` function. This is possible because:

1.  arithmetic is checked and can't over/underflow
2.  zero address is checked and it is not possible to burn tokens through
    `transfer()`

The `Token` contract is simple and it has only two functions. The `totalSupply`
is not used here. The lack of the `0` address check combined with the vulnerable
arithmetics allows for the possible attack vector.

Eve can increase her balance and burn a large number of tokens by sending them
to the 0 address, which would break the economy of the token.

This is not possible in the `Token` contract, because it does not have a real
economy, but I think this type of exploit is important to be kept in mind.

## Plan of the attack

At the beginning of the game, Eve is given 20 tokens to work with.

1.  Eve will call `transfer()` passing her address as the first argument and any
    number larger than 20 as the second one.  
    The `_value` must be larger than the number of tokens that Eve possesses.
2.  Given the `_value` is `>= 20` the left side of the expression in the
    `require` will underflow and wrap to the other side of the uint256 range.
3.  Eve's balance will underflow and it will be equal to the `max_uint` -
    `_value - 20`.
4.  \*We got an issue here: Eve's balance will overflow and return to the
    previous state because her balance will be equal to
    `max_uint - _value - 20 + _value`.

### A potential flaw in my initial plan ❌

My initial hypothesis was that Eve must pass her address to the `transfer()`
function to get the tokens. Once I have outlined the attack plan and analyzed
the `Token` contract in a bit more detail I now think that this approach is
wrong.

I didn't think about it before but Eve can pass any address to the transfer()
function and her balance will be modified anyway. She will also not risk
overflowing it in the end.

### New hypothesis ♻️

My initial hypothesis wasn't specific enough and the mistake was caught when
creating a more specific attack plan. Let's refine it…

Eve can exploit arithmetic underflow to increase her balance to any value via
the transfer() function. She will do so by passing any address different from
hers to the first argument and a number larger than 20 to the second argument.

There is also this flawed case that I would like to test just out of curiosity.
Let's form a hypothesis for that.

If Eve passes her address to the first parameter of the transfer() function and
a number larger than 20 her balance will return to the neutral state of 20
tokens after the transaction is finished.

## Proof of Concept - hypothesis test ✅

At the beginning I wanted to make sure that the risk of the under/overflow is
real. I've created a simple fuzz test that would catch such bug in production.

```solidity
function test_fuzz_transferShouldProperlyUpdateBalances(uint256 value)
	public
{
	// Quick setup of Token contract instance
	Token token;
	token = new Token(21_000_000);

	uint256 balanceBefore = token.balances(msg.sender);
	token.transfer(address(0x123), value);
	uint256 balanceAfter = token.balances(msg.sender);
	assertEq(balanceBefore - value, balanceAfter);
}
```

The assertion fails and returns a counterexample that breaks the function logic:

![Fuzz test counterexample](https://github.com/ChmielewskiKamil/ethernaut-foundry/blob/main/img/05-fuzz-counterexample.png?raw=true)

Now that we know that the risk of integer underflow is real, let's build the
proper attack script...

Here is a simplified version of the unit test exploiting the contract
([Full version here](https://github.com/ChmielewskiKamil/ethernaut-foundry/blob/main/test/05-Token.t.sol)):

```solidity
function test_fuzz_transferShouldProperlyUpdateBalances(uint256 value)
	public
{
	// Quick setup of Token contract instance
	Token token;
	token = new Token(21_000_000);

	uint256 balanceBefore = token.balances(msg.sender);
	token.transfer(address(0x123), value);
	uint256 balanceAfter = token.balances(msg.sender);
	assertEq(balanceBefore - value, balanceAfter);
}
```

Here are the logs from the full version of this test:

![Logs from the 1st hypothesis test](https://github.com/ChmielewskiKamil/ethernaut-foundry/blob/main/img/05-1st-hypothesis-logs.png?raw=true)

The first hypothesis has been proven to be true. Let's prove the second one now.

The unit test is slightly modified. We need to change the address inside the
`transfer()` invocation to be the address of Eve.

```solidity
// as we are using vm.label for Eve's address
// we can simply use her name "eve"
tokenContract.transfer(eve, 21);
```

The second hypothesis has also been proven to be true. Here are the logs from
the full test:

![Logs from the 2nd hypothesis test](https://github.com/ChmielewskiKamil/ethernaut-foundry/blob/main/img/05-2nd-hypothesis-test.png?raw=true)

It turns out that the value inside the `balances` mapping will first underflow
and later overflow which will reset it back to the starting value.

## Slither findings

I wanted to see if I have missed something significant and decided to give
Slither a go. [Slither](https://github.com/crytic/slither) is a static analyzer
created by Trail of Bits. It detects many types of bugs. What is important is
that it detects almost
[80% of the high-severity bugs](https://youtu.be/wT-AmR7wtI8?t=2514).

### Token.transfer contains a tautology

After running Slither on the Token contract, I've got the following finding:

![Transfer function tautology](https://github.com/ChmielewskiKamil/ethernaut-foundry/blob/main/img/05-transfer-tautology.png?raw=true)

The require in the transfer() function contains tautology. It turns out that I
have found a bug that I have not yet fully understood. My thinking was that the
expression inside the require will evaluate to true, because of the underflow.
The true issue however was hiding in plain sight. This expression will always be
true because the type of balances[msg.sender] is uint256. Unsigned integers
cannot be negative by definition. It means that the left side of the expression
will always be >= 0.

### Supply contains too many digits - TokenFactory

![Number with too many digits to be readable](https://github.com/ChmielewskiKamil/ethernaut-foundry/blob/main/img/05-too-many-digits.png?raw=true)

This is the finding that I've managed to discover on my own. This is more of an
informational finding but I believe that solving such fundamental problems will
decrease the likelihood of a serious vulnerability in the long term.

### Supply and playerSupply should be constant - TokenFactory

![State variables should be constant](https://github.com/ChmielewskiKamil/ethernaut-foundry/blob/main/img/05-state-variables-should-be-constant.png?raw=true)

The value of both the playerSupply and supply does not change so they should be
declared as `constant`.

## Recommendations

- For Solidity versions < 0.8.0 the use of SafeMath is recommended
- It is important to have 0 address checks to prevent token burning if it is not
  intended by design.
- Fuzz tests may catch unexpected logic bugs early. It is recommended to have at
  least one fuzz test per function (ex. tools: Echidna, Foundry fuzz tests,
  Mythril, Scribble)
- Make sure that all of the return values are checked. It is safer to have
  functions revert on failure rather than returning a boolean.
- It is suggested to use underscores in the representation of large numbers in
  Solidity to improve readability.  
  `uint supply = 21000000;` --> `uint supply = 21_000_000;`
- State variables that do not change should be declared `constant`.

## References

- Building Better Systems Podcast - Episode #6: Dan Guido -
  [What the hell are blockchain people doing & why isn't it a dumpster fire?](https://youtu.be/wT-AmR7wtI8)
- [Building secure contracts](https://github.com/crytic/building-secure-contracts)-
  Trail of Bits - Slither, Echidna, Manticore tutorials
