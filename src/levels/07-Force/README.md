Saturday, 22nd October 2022 22:57

# Ethernaut Level 7 - Force

You can also read this
[on my blog](https://wizzardhat.com/ethernaut-level-7-force/) 😎

## Objectives

- Make the balance of the smart contract greater than zero.

## Contract Overview

The `Force` contract does not have any code inside. The purpose of this
challenge is to show that even without the logic to handle payments, it is
possible to send ether to the contract and increase its balance.

## Finding the weak spots

Let's step back for a moment and imagine that the `Force` contract handles some
logic that requires checking the inner balance of the smart contract.

It may seem that every possible way of transferring funds into the contract is
covered. This is usually done through the `fallback()`, `receive()`, or any
other `payable` function. Unfortunately, that is not all. A common pitfall is
relying on `this.balance` inside logic checks because you think that contract
tracks all the ether sent to it. Sometimes it is not the case.

The methods outlined above are not the only ways to send ether into the
contract. Ether can also be forcefully transferred via coinbase transaction
(block reward for mining the block) or as a target of the `selfdestruct` (the
beneficiary receives ether from the destroyed contract). Contracts cannot react
to such events and they cannot use it in the intrinsic accounting. This is why
`address(this).balance` should not be used in such checks.

In the context of the `Force` contract, we will use the `selfdestruct` method to
solve the challenge.

## Potential attack scenario - hypothesis

The `selfdestruct` method accepts an address parameter. It is possible to
specify the beneficiary that will receive the balance of the destroyed contract.

_Eve is our attacker_

Eve can trigger `selfdestruct` in the attack contract and specify the address of
the `Force` contract as the target. This way she will increase the balance of
the `Force` contract.

## Plan of the attack

1.  Eve deploys a _ForceAttack_ contract
2.  Eve funds it with any amount of ether
3.  Eve calls the `attack()` function that executes `selfdestruct()`
    - Eve passes an address of the `Force` contract as the target for
      `selfdestruct`
4.  The balance of the `Force` contract is increased

There are many ways to achieve this goal. The address can be passed in the
`constructor` or `selfdestruct` and can be triggered inside the `fallback()`
function when poked by the low-level call. A contract can be also funded during
deployment.

There are many possible solutions. I will experiment with them and present one
below.

## Proof of Concept - hypothesis test ✅

The hypothesis has been proven to be true. The balance of the `Force` contract
can be increased with `selfdestruct`.

This is what the attack contract looks like:

```solidity
contract ForceAttack {
	address forceContractAddress;

	constructor(address _forceContractAddress) public {
		forceContractAddress = _forceContractAddress;
	}

	function attackForceContract() public {
		selfdestruct(payable(forceContractAddress));
	}
}
```

Here is a simplified version of the unit test exploiting the contract
([Full version here](https://github.com/ChmielewskiKamil/ethernaut-foundry/blob/main/test/07-Force.t.sol)):

```solidity
// forceAttack is the instance
// of the ForceAttack contract
forceAttack.attackForceContract();
```

Here are the logs from the exploit:

![Logs from the exploit](https://github.com/ChmielewskiKamil/ethernaut-foundry/blob/main/img/07-test-logs.png?raw=true)

## Recommendations

- Intrinsic accounting should not rely on the contract balance because ether can
  be forcefully sent to the contract.

## References

- [Solidity by Example - Self Destruct](https://solidity-by-example.org/hacks/self-destruct/)
