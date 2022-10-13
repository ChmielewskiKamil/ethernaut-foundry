# Level 4 - Telephone

## Objectives

- claim ownership of the contract

## Contract Overview

The first thing that caught my attention in the `Telephone` contract was the
condition inside the `if` statement. In the `changeOwner()` function the
`tx.origin != msg.sender` check is exactly the opposite of what I suggested in
the recommendations on the previous level. In the `CoinFlip` contract, it would
have been good to check if the caller is an EOA, to make sure that contracts are
not part of the game. It could have been done with `tx.origin == msg.sender`.

In the `Telephone` contract, it is the opposite. The contract is checking if the
caller is a smart contract.

A `Telephone` contract has one function `changeOwner` which allows any smart
contract to change the owner of the `Telephone` contract.

## Finding the weak spots

The `changeOwner` is responsible for the critical action of changing ownership.
However, it is not protected by any security checks (like `onlyOwner` modifier).
It allows anyone to change the owner of the smart contract which is probably not
intended.

The `Telephone` contract relies on the `tx.origin` which is prone to
[phishing attacks](https://github.com/crytic/slither/wiki/Detector-Documentation#dangerous-usage-of-txorigin).
It might also be
[removed in the future](https://ethereum.stackexchange.com/questions/196/how-do-i-make-my-dapp-serenity-proof/200#200),
which may result in compatibility issues.

The contract also does not emit events on
[the critical access control parameters](https://github.com/crytic/slither/wiki/Detector-Documentation#missing-events-access-control),
which makes it difficult to track the ownership changes off-chain.

## Potential attack scenario - hypothesis

_Eve is our attacker_

Eve can create a smart contract, which will call the `Telephone` contract and
change the owner to Eve.

## Plan of the attack

1. Eve calls the `attack` function on her `TelephoneExploit` contract.
2. The `attack` function makes a call to the `Telephone` contract.
3. This call invokes the `changeOwner` function with Eve's address as an
   argument.
4. The ownership is claimed by Eve.

## Proof of Concept - hypothesis test ✅

Here is the `TelephoneExploit` contract:

```solidity
contract TelephoneExploit {
	Telephone telephone;

	constructor(address _telephoneContractAddress) public {
		telephone = Telephone(_telephoneContractAddress);
	}

	function attack(address _newOwner) public {
		telephone.changeOwner(_newOwner);
	}
}
```

Simplified version of the unit test that shows the exploit
([full version here](https://github.com/ChmielewskiKamil/ethernaut-foundry/blob/main/test/04-Telephone.t.sol)):

```solidity
telephoneExploit.attack(eve);
```

Here are the logs from the exploit:

![Logs from the Telephone exploit](https://github.com/ChmielewskiKamil/ethernaut-foundry/blob/main/img/04-Telephone-exploit-logs.png?raw=true)

## Recommendations

- The use of some form of access control is recommended. An example of that
  might be OpenZeppelin Ownable, which provides a basic access control mechanism
  or OZ AccessControl which provides role-based access control.
- The use of `tx.origin` should be removed from the contract.
- Emission of events should be added to the critical `changeOwner()` function.
  It will result in better communication with off-chain components and a better
  user experience overall.

## References

- [Usage of tx.origin - ToB - Slither Detector](https://github.com/crytic/slither/wiki/Detector-Documentation#dangerous-usage-of-txorigin)
- [Missing events on access control - ToB - Slither Detector](https://github.com/crytic/slither/wiki/Detector-Documentation#missing-events-access-control)
- [Tx.origin might not be usable in the future - V. Buterin](https://ethereum.stackexchange.com/questions/196/how-do-i-make-my-dapp-serenity-proof/200#200)
- [More info on tx.origin - Consensys Diligence](https://consensys.github.io/smart-contract-best-practices/development-recommendations/solidity-specific/tx-origin/)
