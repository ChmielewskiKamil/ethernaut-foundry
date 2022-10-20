# Level 2 - Fallout

You can also read this
[on my blog](https://wizzardhat.com/ethernaut-level-2-fallout/) 😎

## Objectives

- claim ownership of the contract

## Contract Overview

The `Fallout` contract works like a bank. It allows users (allocators) to
allocate ether into their separate balances.

- User can deposit money via `sendAllocation()` function.
  - Their allocation will be saved in the `allocations` mapping.
- Users can withdraw the money at any time via the `sendAllocation()` function
  by specifying themselves as the beneficiary in the function parameter.
- Users can also send their allocations to other allocators (they need to be
  present in the mapping) via the same `sendAllocation()` function.
- The owner of the `Fallout` contract can withdraw all of the gathered funds at
  any time via the `collectAllocations()` function.
- It is also possible to check the current balance of any allocator via the
  `allocatorBalance()` function.

## Finding the weak spots

The main issue with the `Fallout` contract is the typo in the `constructor` name
(It was spelled as `Fal1out` instead of `Fallout`). Please recall that in
Solidity versions below 0.4.22 the constructor had to have the same name as the
contract. The `constructor` keyword was introduced in Solidity version 0.4.22.
From version 0.4.22 up to 0.5.0, both naming conventions were possible. Since
0.5.0 only the `constructor` keyword is allowed.

`Fallout` contract uses the `^0.6.0` Solidity version pragma. Its constructor is
invalid and does not work properly. `Fal1out()` can be called just like any
other public function because it is not protected.

Apart from this issue, there are couple more problems in the `Fallout` contract.

- The contract does not emit `events` on critical functions `allocate()`,
  `sendAllocation()` and `collectAllocations()`. Point 45. from the Secureum
  Security Pitfalls and Best Practices 101
  > **Missing events**: Events for critical state changes (e.g. owner and other
  > critical parameters) should be emitted for tracking this off-chain.
- The contract does not have the time lock mechanism on the critical
  `collectAllocations()` function which lefts users no time to withdraw their
  funds before the owner. Point 182. from the Secureum Solidity 201
  > OpenZeppelin TimelockController: acts as a timelocked controller. When set
  > as the owner of an Ownable smart contract, it enforces a timelock on
  > all *onlyOwner* maintenance operations. This gives time for users of the
  > controlled contract to exit before a potentially dangerous maintenance
  > operation is applied. By default, this contract is self administered,
  > meaning administration tasks have to go through the timelock process.

## Potential attack scenario - hypothesis

_Eve is our attacker_

Eve can call the faulty constructor and claim ownership of the contract. She can
then withdraw all the allocations. This way she will drain the contract balance.

## Plan of the attack

1. Eve can call the `Fal1out()` function which will set her as the owner of the
   `Fallout` contract.
2. As the owner of the contract Eve can call `collectAllocations()` function and
   withdraw the contract balance.

## Proof of Concept - hypothesis test ✅

Here is a simplified version of the unit test exploiting the vulnerability
([Full version here](https://github.com/ChmielewskiKamil/ethernaut-foundry/blob/main/test/02-Fallout.t.sol))

```solidity
// Eve calls the `Fal1out()` function
// she claims the ownership
falloutContract.Fal1out();

// Eve calls the `collectAllocations()` function
// and drains the contract balance
falloutContract.collectAllocations();
```

Here are the logs from the exploit:

![Logs from the fallout exploit](https://github.com/ChmielewskiKamil/ethernaut-foundry/blob/main/img/Fallout.png?raw=true)

## Recommendations

1. \[CRITICAL\] The constructor of the `Fallout` contract should be fixed. Here
   is an example fix:

```solidity
constructor () public payable {
	owner = msg.sender;
	allocations[owner] = msg.value;
}
```

2. The emission of events should be added to the critical contract functions
   that modify the state of the contract. This will allow for better
   communication with off-chain components. It will also provide users with a
   better sense of what is happening inside the contract.
3. The use of OpenZeppelin TimelockController is recommended on
   `collectAllocations()` function to provide a better user experience and
   increase safety.

## Additional links

- https://github.com/crytic/slither/wiki/Detector-Documentation#missing-events-access-control
- https://secureum.substack.com/p/security-pitfalls-and-best-practices-101
- https://secureum.substack.com/p/solidity-201
