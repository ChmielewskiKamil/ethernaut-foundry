
# Ethernaut Level 17 - Recovery

You can also read this [on my blog](https://wizzardhat.com/ethernaut-level-17-recovery/) 😎

## Objectives

- Recover ether from the token contract.

## Contract Overview

It took me a while to understand what the goal of this challenge was. In short, someone created a `SimpleToken` contract, sent there some Ether and forgot about it. We need to find the contract and recover the Ether. Since Ethereum is a [Dark Forest](https://www.paradigm.xyz/2020/08/ethereum-is-a-dark-forest), this would probably never succeed because we would be sniped by the MEV searchers.

The main "challenge" in this level is actually finding the address of the lost token contract. Since I am solving Ethernaut locally in Foundry, this is not really an issue since call traces will show me exactly where the `SimpleToken` was deployed.

Another way to find this address would be to simply look at the contracts created by the token factory on Etherscan. Since I am solving this locally this is not an option.

The third way is to calculate the address. I've done some googling to see how to pre-compute the `SimpleToken` address. [Ethereum stackexchange provided me with this weird formula](https://ethereum.stackexchange.com/questions/760/how-is-the-address-of-an-ethereum-contract-computed):

```solidity
address addr = address(uint160(uint256(keccak256(abi.encodePacked(bytes1(0xd6), bytes1(0x94), sender, bytes1(0x01))))));
```

where `sender` is the address of the account that deploys the new contract.

I've tested it out in [Solidity REPL - Chisel (Foundry feature)](https://book.getfoundry.sh/reference/chisel/?highlight=chisel#chisel).

1. Start Chisel with: `chisel`
2. Calculate the address: `address addr = address(uint160(uint256(keccak256(abi.encodePacked(bytes1(0xd6), bytes1(0x94), 0xffD4505B3452Dc22f8473616d50503bA9E1710Ac, bytes1(0x01))))))` (I got the address from test traces with `forge test -vvvvv` )
3. Return the result with: `addr`

The resulting address, `0x41cfce597382f595e5030a62ff8b7c24b40cfe87`, is the same as the one from the call traces. I would love to understand this solution fully, and I will have to dive into [Huff](https://huff.sh/) to understand how [the RLP encoding](https://ethereum.org/en/developers/docs/data-structures-and-encoding/rlp/) works under the hood. Unfortunately, for now, I couldn't grasp it. [The Ethereum Under the Hood - Part 2 blog post](https://medium.com/coinmonks/ethereum-under-the-hood-part-2-rlp-encoding-ver-0-3-c37a69781855) explains the topic well, but I still couldn't apply this knowledge to calculate the address for this challenge.

## Finding the weak spots

The `SimpleToken` contract does not have the concept of contract ownership. The `creator` is set in the constructor, but this variable is only used to assign the initial token supply to the contract's creator. At the bottom of the `SimpleToken` contract, there is an unprotected `destroy()` function. There is no `onlyOwner` or `onlyCreator` modifier. Since this is a public function, it can be called by anyone.

## Potential attack scenario - hypothesis

*Eve is our attacker*

Eve can call the `destroy()` function on the `SimpleToken` contract and send the contract's Ether balance to herself (as a target of selfdestruct).

## Plan of the attack

1. Calculate the `lostToken` address
2. Eve calls the `destroy` function on the `lostToken` and transfers the funds to herself.

## Proof of Concept - hypothesis test ✅

The PoC is simple. Use any of the methods presented in the overview to calculate the token address, call the `destroy`, funds transferred. [Code is available on my GitHub](https://github.com/ChmielewskiKamil/ethernaut-foundry/blob/main/test/17-Recovery.t.sol).

```solidity
address payable lostTokenAddress = payable(
 address(0x41cFCe597382f595E5030a62Ff8b7C24b40CFE87)
);
SimpleToken lostToken = SimpleToken(lostTokenAddress);
lostToken.destroy(eve);
```

## References

- [Ethereum Stackexchange - How is the address of an Ethereum contract computed](https://ethereum.stackexchange.com/questions/760/how-is-the-address-of-an-ethereum-contract-computed)
- [Ethereum Under the Hood - Part 2](https://medium.com/coinmonks/ethereum-under-the-hood-part-2-rlp-encoding-ver-0-3-c37a69781855)
- You can also read this [on my blog](https://wizzardhat.com/ethernaut-level-17-recovery/) 😎
