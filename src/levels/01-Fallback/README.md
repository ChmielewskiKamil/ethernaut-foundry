# Level 1 - Fallback

## Objectives

- claim ownership of the contract
- reduce its balance to 0

## Contract Overview

The fallback contract allows users to contribute ether to the contract. The
contract is supposed to work as follows:

- if a user contributed more than the owner, he then becomes the owner
- the owner can withdraw all of the funds

## Potential pitfalls

The fallback contract contains a `receive()` function that at first glance
contains flawed logic. The `receive()` function bypasses the main logic of a
contract. It does not check if the amount of ether contributed by the user is
larger than that of the owner.

## Attack vectors - hypothesis

If one sends ether directly to the contract via external call, one can become
the owner of the contract without the need to contribute more than the owner.
