# Ethernaut Level 6 - Delegation

You can also read this
[on my blog](https://wizzardhat.com/ethernaut-level-6-delegation/) 😎

## Objectives

- Claim ownership of the smart contract.

## Contract Overview

`Delegation.sol` contains two contracts. The objective of this challenge is to
take ownership of the `Delegation` contract. There is also a `Delegate` contract
which handles the logic of changing the owner of the `Delegation` contract.

When I first saw these contracts I had a hard time understanding what is going
on. The names _Delegation_ and _Delegate_ were not clear to me at all.

If we step back for a moment and imagine that this challenge represents a proxy
pattern, the solution becomes much easier to grasp.

If you recall, in the proxy pattern, two contracts are needed. The first one is
the proxy contract (also known as the storage layer). In our case, this is the
`Delegation` contract. It delegates calls to the second type of contract via
`delegatecall` in the `fallback()` function. This second contract is the
implementation contract (also known as the logic layer). In our case, this is
the `Delegate` contract.

## Finding the weak spots

Please keep in mind that this section on finding potential vulnerabilities is
just a scratchpad for my thoughts. Not all of the findings outlined here might
be proven to be valid after we investigate the contract to a greater extent.

- The public function `pwn()` modifies the state but is not protected by any
  modifier.
- The `Delegation` contract contains a `delegatecall` with user-controlled
  input. The ability of a malicious user to exploit this particular call is
  limited because the address to which the `delegatecall` is done
  [is not user-controlled](https://github.com/crytic/slither/wiki/Detector-Documentation#controlled-delegatecall).
  The user still provides the `msg.data` which is dangerous because he can
  specify any function he wants to be invoked with any value.
- The return value of the `delegatecall` is not checked. It may result in silent
  failures.
- The `if` statement in the `fallback()` function is a redundant code. It does
  nothing.
- There is no 0 address check in the `constructor` of the `Delegate` contract.

Claiming ownership of the contract might be a possible goal to achieve by
abusing the unsafe `delegatecall`. Let's explore that further...

## The inner workings of the delegatecall

_Eve is our attacker_

To fully understand how _Eve_ can use the `delegatecall` to claim ownership of
the contract, some background knowledge of `delegatecall` properties is
necessary.

The `delegatecall` is state preserving - it operates on the allocated slots of
memory. It sounds scary but it is not. Please recall how the basic
`delegatecall` works. Contract A (the caller) does `delegatecall` to contract B
(the callee). It means that the logic from contract B will be used with the
state (ex. storage variables) from contract A.

But how does the logic inside contract B know which state variables from A need
to be used? This is the problem that all proxy-based contracts face. The
simplest solution (used in the `Delegation.sol`) is
[Inherited Storage](https://mvpworkshop.co/blog/upgradeable-smart-contracts-proxy-pattern/).
This is the approach where both the proxy and the implementation have the same
storage structure. It means that their variables are declared in the same order.
[The layout, the type and the mutability also have to match.](https://secureum.substack.com/p/security-pitfalls-and-best-practices-101)
The names however can be different. This way, contract B is aware of the state
variables present in A and executes the logic on the state of A. This agreement
between two contracts is based on trust. The trust that the developer didn't
make any mistakes and that the storage slots match in both of the contracts.
Because if it is not the case, the wrong variables will be modified and it may
lead to some serious vulnerabilities or even contract hijacking by malicious
proxies.

## Potential attack scenario - hypothesis

Eve can claim ownership of the `Delegation` contract by making a low-level call
to it.

Eve will use the `delegatecall` inside the `Delegation` contracts `Fallback()`
function. It will perform a call to the `Delegate` contracts `pwn()` function.
The `pwn()` function will execute its logic with the execution context of Eve
but at the same time, it will modify the state of the `Delegation` contract.

## Plan of the attack

1. Eve makes a low-level call to the `Delegation` contract.
   1. Eve will need to provide the selector of the `pwn()` function as the
      `msg.data`.
   2. To calculate the selector Eve needs a `pwn()` function signature. The
      signature is created by taking the function name and appending it with the
      types of parameters inside the parenthesis. The `pwn()` function does not
      have any parameters. The signature will look like this: `pwn()`
   3. The function selector is the first four bytes of the keccak256 hash of the
      `pwn()` function signature. It will be calculated using the built-in
      `abi.encodeWithSignature` method.
2. By making this call, the implementation contract (the `Delegate`) will modify
   the storage of the proxy contract (the `Delegation`).
3. The `Delegate` contract will use the execution context of the account that
   initiated the transaction (in this case: it's Eve) -> `msg.sender` will be
   equal to Eve's address.
4. Eve claims ownership.

Let's put this plan to the test...

## Proof of Concept - hypothesis test ✅

Here is a simplified version of the unit test exploiting the contract
([Full version here](https://github.com/ChmielewskiKamil/ethernaut-foundry/blob/main/test/06-Delegation.t.sol)):

```solidity
(bool success, ) = address(delegationContract).call(
	abi.encodeWithSignature("pwn()")
);
require(success, "Transaction failed");
```

The hypothesis has been proven to be true. Here are the logs from the test:

![Unit test logs](https://github.com/ChmielewskiKamil/ethernaut-foundry/blob/main/img/06-test-logs.png?raw=true)

We can increase the verbosity of the test and see what is happening under the
hood:

![High verbosity unit test logs](https://github.com/ChmielewskiKamil/ethernaut-foundry/blob/main/img/06-high-verbosity-logs.png?raw=true)

Let's see if Slither can find some additional vulnerabilities that I may have
missed... 🕵🏻‍♂️

## Slither findings

This time it seems that we have found every vulnerability that could be possibly
found with Slither. Every single one has already been pointed out in the
"Finding the weak spots" section. I will present you just the high-severity
Slither finding because it is the key to completing this particular Ethernaut
challenge.

High-severity finding: Delegatecall with input controlled by the user

![High-severity slither finding](https://github.com/ChmielewskiKamil/ethernaut-foundry/blob/main/img/06-user-controlled-delegatecall.png?raw=true)

## Recommendations

- The use of the `delegatecall` should be avoided. If it is necessary to use it,
  ensure that only trusted parties can call it. Moreover, particular attention
  needs to be paid to the input that can be provided by the user. It is
  discouraged to let users decide to which address the `delegatecall` should be
  made. Additionally, functions that proxy users are allowed to invoke at the
  destination address should be protected with some form of access control (like
  a whitelist for example).
- Functions in the implementation contracts should be protected. An
  implementation is a standalone contract, so it can be called directly without
  the use of a proxy (see
  [Parity Multi-sig bug 2](https://www.parity.io/blog/a-postmortem-on-the-parity-multi-sig-library-self-destruct/)).
- The return value from low-level calls should be checked. The `fallback()`
  function contains redundant code. The `if` statement does nothing and it
  should be replaced with a proper return value check. For example:

```solidity
require(result, "Delegatecall failed")
```

- Making ownership changes without the 0 address check may lead to the
  [loss of ownership](https://github.com/crytic/slither/wiki/Detector-Documentation#missing-zero-address-validation)
  of the contract. If the address is not specified, the default value of the
  address type will be used -> the 0 address. The contract will be locked
  forever.

## References

- Read this [on my blog](https://wizzardhat.com/ethernaut-level-6-delegation/)
  😎
- [Trail of Bits - Slither - Controlled Delegatecall](https://github.com/crytic/slither/wiki/Detector-Documentation#controlled-delegatecall)
- [MVP Workshop - Proxy Pattern](https://mvpworkshop.co/blog/upgradeable-smart-contracts-proxy-pattern/)
- [The Secureum - Security Pitfalls and Best Practices 101](https://secureum.substack.com/p/security-pitfalls-and-best-practices-101)
  (point 99)
- [SWC-112 Delegatecall to Untrusted Callee](https://swcregistry.io/docs/SWC-112)
- [Trail of Bits - Slither - Missing zero address validation](https://github.com/crytic/slither/wiki/Detector-Documentation#missing-zero-address-validation)
