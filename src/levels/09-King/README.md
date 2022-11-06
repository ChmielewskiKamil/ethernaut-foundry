# Ethernaut Level 9 - King

You can also read this
[on my blog](https://wizzardhat.com/ethernaut-level-9-king/) 😎

## Objectives

- Break the game! Don't allow the level to reclaim the kingship of the instance.

## Contract Overview

The `King` contract is a simple Ponzi game. Players send ether to the contract
(a prize). Whoever sends the most ether becomes the new king. The old king gets
the new prize. He earns the difference between the new prize and the old prize
(the prize that he set).

## Finding the weak spots

The only issue that I have managed to find in the `King` contract is the
violation of the Checks Effects Interactions pattern.

- Interactions with other accounts should be done as the last step. Required
  checks should be made first, state changes second and transfers, calls, and
  function invocations should be made last.
- Violation of the CEI pattern may cause reentrancy attacks.

For now, my only idea to break the contract is that a malicious contract may
trick the `King` contract into calling a `delegatecall` that will change the
owner of the contract, which will prevent the level from claiming the kingship.
This solution is far from perfect and I will explain it below.

**Update** A second idea popped into my head after a little bit of rest. Maybe
it is possible to break the contract by sending ether through selfdestruct.

## Potential attack scenario - hypothesis

_Eve is our attacker_

_Hypothesis 1_

Eve uses a smart contract (`KingAttack`) to send ether to the contract. The
contract becomes the king. She sends ether again. The `king.transfer` function
triggers the malicious `receive()` function which contains a `delegatecall` that
changes the owner using the storage from the `King` contract and logic from the
`KingAttack` contract.

I think this hypothesis should be false because the `transfer` and `send`
functions were introduced to prevent reentrancy attacks. They are limited to
2300 gas and a `delegatecall` if I recall correctly uses around 2600.

I am not 100% sure so we will have to check this out if nothing better comes to
my mind.

Also, I don't think that the contract can perform a delegatecall to himself, so
probably a third contract would be needed.

_Hypothesis 2_ - _(update 1)_

Eve can send Ether to the contract using `selfdestruct` on the attack contract.
It will transfer `msg.value` (attack contract balance) to the current king
(level factory) and set the new king to be the address of the destroyed
contract. It might break future transfers of Ether.

Now that I wrote it down, I am almost certain that this is not going to work
because there is no EVM level check if the address is valid or not. It is up to
the user to check it. The `transfer` function will work perfectly fine.

When I think about it, making the transfer function fail might be the key to
solving this challenge.

_Hypothesis 3_ - _(update 2)_

Eve can send funds to the `King` contract via a `KingAttack` contract. The
`KingAttack` contract will become the king. It will contain a `receive()`
function that will revert on every transfer, making it impossible to transfer
money and set the new king.

I think this is going to work because of the violation of the CEI pattern. A
failing transfer will block the ability to change the king (interactions before
the state changes).

Now the only question is how to make the `receive()` function fail on every
transfer. Two things come to my mind.

1. adding `revert()` to the `receive()` function
2. not adding `payable` to the `receive()` function will make it impossible to
   send ether via `transfer()`

Let's test both of these...

## Plan of the attack

1. Eve creates a `KingAttack` contract that contains two functions:
   - an `attack()` function that will send Ether to the `King` contract and
     claim kingship (`msg.value` has to be bigger than the current `prize`)
   - `payable receive()` function that explicitly reverts OR `receive()`
     function without the `payable` state mutability
2. Eve calls the `attack()` function
3. The game is broken
4. Game Level cannot claim kingship because the `transfer()` function reverts
   every time it tries to send the prize to the previous king

## Proof of Concept - hypothesis test ✅

The use of the `receive()` function has been proven to be a valid way of
breaking the game. However, creating a `receive()` function without the payable
keyword is impossible. Compiling the code without this keyword results in an
error:

_TypeError: Receive ether function must be payable, but is "nonpayable"._

I am curious why it is the case. I am aware of the
[syntax changes](https://docs.soliditylang.org/en/latest/060-breaking-changes.html#semantic-and-syntactic-changes)
introduced in the 0.6.0 version of Solidity. From that point, the unnamed
functions had to be specified with the `receive` and `fallback` keywords. When
it comes to the `payable` state mutability specifier the documentation says that
the `receive()` function is implicitly `payable`. Why the error then? I couldn't
find any changes in the later versions either. In
[Secureum Solidity 101](https://secureum.substack.com/p/solidity-101) point 33
says:

_\[about receive function\]... This function cannot have arguments, cannot
return anything and must have external visibility and payable state mutability._

For now, I have to accept that it has to be explicitly payable. Let's explore
the second idea...

Making the `receive()` function revert no matter what, broke the game and solved
the challenge.

```solidity
receive() external payable {
	revert();
}
```

You can check the full attack contract `KingAttack.sol`
[here](https://github.com/ChmielewskiKamil/ethernaut-foundry/blob/main/src/levels/09-King/KingAttack.sol).

Here are the logs from the exploit:

![Logs from the King exploit](https://github.com/ChmielewskiKamil/ethernaut-foundry/blob/main/img/09-logs-from-the-exploit.png?raw=true)

This is the simplified version of the PoC unit test showcasing the issue
([full version here](https://github.com/ChmielewskiKamil/ethernaut-foundry/blob/main/test/09-King.t.sol)):

```solidity
KingAttack kingAttack = new KingAttack(address(kingContract));
kingAttack.attack{value: 1 ether}();
```

In combination with the malicious `receive()` function, it makes the game
unplayable.

## Recommendations

- Apply the check-effects-interactions pattern. Making interactions before the
  state changes introduce an opening for the reentrancy attack.

## References

- You can also read this
  [on my blog](https://wizzardhat.com/ethernaut-level-9-king/) 😎
- [Solidity 0.6.0 Breaking Changes - payable receive and fallback functions](https://docs.soliditylang.org/en/latest/060-breaking-changes.html#semantic-and-syntactic-changes)
- [The Secureum - Solidity 101](https://secureum.substack.com/p/solidity-101)
