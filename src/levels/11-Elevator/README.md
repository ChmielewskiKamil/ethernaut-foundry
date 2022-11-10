# Ethernaut Level 11 - Elevator

You can also read this
[on my blog](https://wizzardhat.com/ethernaut-level-11-elevator/) 😎 Source:

## Objectives

- Reach the top floor!

Set the `bool public top` to `true`.

## Contract Overview

To understand how the `Elevator` contract works, it is necessary to understand,
how interfaces work. This
[great article](https://medium.com/coinmonks/solidity-tutorial-all-about-interfaces-f547d2869499)
from [Jean Cavallera](https://twitter.com/JeanCavallera) can get you up to speed
with all the information you may need to understand this topic.

In short, interfaces define the functionality of a smart contract and how to
trigger that functionality. They don't, however, define how to implement certain
features. They leave that to the developer.

## Finding the weak spots

The implementation of an interface can contain arbitrary logic. This property
imposes some risk when it comes to interacting with such smart contracts. The
implementation might contain malicious code.

The `Elevator` contract expects us - the `Building`, to tell it whether the
floor we want to go to is the last one. If we behave honestly and tell it that
the specific floor is the one on the top (return `true` from `isLastFloor()`),
the `Elevator` contract won't let us reach it. The following statement will be
equal to false because of the exclamation mark at the beginning:

```solidity
if (!building.isLastFloor(_floor))
```

To reach the top floor we need to pass this check. It would be possible if we
could return `false` in the `isLastFloor()` function. There is still one
problem...

Let's look at the `Elevator` contracts logic:

```solidity
// we pass this check -->
// we get inside the "if" block
if (!building.isLastFloor(_floor)) {
	// we reach the top floor
	floor = _floor;

	// but this also evaluates to false
	// and to complete the challenge we need
	// to set this to true
	// what now????
	top = building.isLastFloor(floor);
}
```

If the `isLastFloor()` function always returns false, we won't pass the
challenge. We need a way to `return false` the first time this function is
called and `return true` the second time. How to achieve this? It would be best
if we could hook the return value to some property that changes between those
two calls.

We have such property - it is the state variable `floor`. We set it from the
default - uninitialized value to the value passed in the `_floor` argument.

We should return `false` when the `floor` is uninitialized (value of `0`) and
`true` when it is set to something. I am not sure about this 100% so let's form
the hypothesis and test it.

## Potential attack scenario - hypothesis

_Eve is our attacker_

Eve can create the attack contract that will inherit the `Building` interface.
This contract will implement the `isLastFloor` function in a way that will
return forged results. This way she will set the boolean `top` to the value of
true.

## Plan of the attack

1. Eve deploys the `ElevatorAttack` contract.
2. She calls the `goToTopFloor()` function on this contract.
   1. It calls the `Elevator` contracts `goTo(uint256)` function (attack
      function can pass arbitrary value, it doesn't matter)
   2. The `Elevator` contract calls back to the `ElevatorAttack` contract.
3. The `isLastFloor()` function implemented by Eve will return:
   1. `false` in the first invocation (when the `floor` is not assigned any
      value)
   2. `true` in the second invocation (when the `floor` is set to the `uint`
      value passed in the `goTo()` function)
4. The `bool top` is set to the value of true.

## Proof of Concept - hypothesis test ✅

The hypothesis has been proven to be true. Here is a fragment of the
`ElevatorAttack.sol`
([full version here](https://github.com/ChmielewskiKamil/ethernaut-foundry/tree/main/src/levels/11-Elevator/ElevatorAttack.sol)):

```solidity
// ... snippet

// Notice that the input parameter is never used in this func
// it is still necessary to implement it
// because of how the interfaces work
function isLastFloor(uint256 _floor) external override returns (bool) {
	if (elevator.floor() == 0) {
		return false;
	} else {
		return true;
	}
}

function goToTopFloor() public {
	elevator.goTo(100);
}
```

Here is a simplified version of the unit test showcasing the exploit
([full version here](https://github.com/ChmielewskiKamil/ethernaut-foundry/blob/main/test/11-Elevator.t.sol)):

```solidity
elevatorAttack.goToTopFloor();
```

The whole logic is in the `ElevatorAttack` contract. Eve just needs to call the
`goToTopFloor()` function.

## Recommendations

- Interactions with other contracts always come with a certain level of threat.
  Because interfaces can contain arbitrary logic, it is especially important to
  treat them with caution. Contracts that you call may re-enter your contract.
  It is recommended to apply the checks-effects-interactions pattern to avoid
  making external calls before making state changes.
- Apply the recommendations outlined above to the `goTo` function in the
  `Elevator.sol`.

## References

- [Solidity Tutorial: all about interfaces - Jean Cavallera](https://medium.com/coinmonks/solidity-tutorial-all-about-interfaces-f547d2869499)
- You can also read this
  [on my blog](https://wizzardhat.com/ethernaut-level-11-elevator/) 😎
