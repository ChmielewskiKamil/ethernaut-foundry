# Ethernaut Level 14 - GatekeeperTwo

You can also read this \[on my blog\](https://wizzardhat.com/ethernaut-level-14-gatekeepertwo/) 😎

## Objectives

- Make it past the gatekeeper! ([same thing as in Gatekeeper One](https://wizzardhat.com/ethernaut-level-13-gatekeeperone/))

Register as an entrant -> change the `entrant` to your address.

## Contract Overview
The `GatekeeperTwo` contract is very similar to the `GatekeeperOne`. It shares the same `enter()` function and the `gateOne` modifier. Gates two and three are different. The second gate uses inline assembly which is considered a dangerous practice. I will have to investigate the inner workings of the `extcodesize` instruction. The third gate uses bitwise XOR operation so I expect that it will be required to perform some binary tricks to pass that modifier. 

## Finding the weak spots

The first thing that I've noticed is the lack of revert strings inside the modifiers. It was a pain to debug in the previous challenge because of that. This issue is present in all of the modifiers of the `GatekeeperTwo` contract. 

### The second gate 
According to the [Solidity documentation](https://docs.soliditylang.org/en/v0.4.23/assembly.html), the `extcodesize(a)` opcode returns the size of the code at the address `a`. The `caller` opcode returns the address of the call sender. When we combine these two things we will get the code size of the sender account. 

If we also take into consideration the condition from the first gate, things start to become a little bit complicated. To pass both gates the call has to be made from a contract account that has a code size equal to zero. 

This condition can be satisfied if the call would be made from the contract that is under construction. 

> Secureum Solidity 201 point 159a:
> 
> _isContract(address account)_ → _bool_: Returns true if account is a contract. It is unsafe to assume that an address for which this function returns false is an externally-owned account (EOA) and not a contract. Among others, isContract will return false for the following types of addresses: 1) an externally-owned account ==2) a contract in construction== 3) an address where a contract will be created 4) an address where a contract lived, but was destroyed

and

> Secureum Security Pitfalls & Best Practices 101 point 31:
> 
> **Contract check:** Checking if a call was made from an Externally Owned Account (EOA) or a contract account is typically done using _extcodesize_ check which may be circumvented by a ==contract during construction== when it ==does not have source code available==. Checking if _tx.origin == msg.sender_ is another option. Both have implications that need to be considered. (see [Consensys best practices for smart contract security](https://consensys.net/blog/blockchain-development/solidity-best-practices-for-smart-contract-security/))

### The third gate
Bitwise XOR (`^`) operator is used in the `require` function. I wasn't sure what the order of operations is in Solidity. The question was whether the XOR `^` operator would take precedence over the equality operator `==` or not. There could be two possible outcomes:

```
Option 1 (uint64 ^ uint64) == type(uint64)

Option 2 (uint64) ^ (uint64 == type(uint64))
```

According to Solidity Docs - [Order of Precedence of Operators](https://docs.soliditylang.org/en/v0.4.23/miscellaneous.html#order-of-precedence-of-operators) - Bitwise XOR takes precedence over the equality operator. It means that the 1st option is the valid one. 

Now that we know that, the question is how to pass the third gate.

Bitwise XOR returns `1` only if either of the two bits is 1 but not both. Let's illustrate that:

```
Number 1    1010
XOR ^
Number 2    1111
----------------
Result      0101
```

To pass the `require` statement the `uint64` from the address of `msg.sender` XOR'ed (`^`) with the `uint64` gate key has to be equal to the `type(uint64).max`. What is the max value of the `uint64` you may ask? We don't need to know the decimal number, just the binary/hex representation.

If you recall `1 byte` is `8 bits`. The size of `uint8` (`uint` 8 bits!) is `1 byte`. It means that the max value that the `uint8` type can store is `11111111` - eight `1`s. We can also represent that in hex. Each hex digit (`1 nibble`) - half a byte is 4 digits. The max value that `uint8` can store is `0xFF`.

What would be the decimal representation of the maximum value that `uint64` can store?

It would be sixty-four `1`s or 16 hex digits - `0xFFFFFFFFFFFFFFFF`.

So the task is to achieve this number by tweaking the gate key or masking the `msg.sender` address. How do we do that?

I have a couple of ideas but I thought that it would be cool if we could have someone or something crack this level for us. 

I am curious whether a tool like [Echidna smart contract fuzzer](https://github.com/crytic/echidna) could rent us a hand. The `bytes8` is not that big of a number so I think that it actually might succeed. For a larger set of possibilities, a [symbolic execution tool like Manticore](https://github.com/trailofbits/manticore) would be better. 

I've recently attended an [Echidna workshop from Trail of Bits](https://www.youtube.com/watch?v=bhb_y80iF8w) conducted by [@anishrnaik](https://twitter.com/anishrnaik), [@technovision99](https://twitter.com/technovision99) and [@0xicingdeath](https://twitter.com/0xicingdeath) so now is the time to put the skill into practice. 

### Fuzzing the contract with Echidna
I've created a simpler version of the `GatekeeperTwo` contract. It contains only the third gate. 

You can think of Echidna as an EOA (externally owned account). It will call the contract with pseudo-random input. In addition, it will call contract functions in different sequences to cover as many paths as possible. Echidna is a property-based fuzzer, which means that it will try to generate transactions that will break the property that you want to test. 

Here is the contract that I will be testing:
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EchidnaExample {
	address public entrant;
	
	modifier gateThree(bytes8 _gateKey) {
		require(
			uint64(bytes8(keccak256(abi.encodePacked(msg.sender)))) ^
			uint64(_gateKey) ==
			type(uint64).max
		);
		_;
	}
	
	function enter(bytes8 _gateKey) public gateThree(_gateKey) returns (bool) {
		entrant = tx.origin;
		return true;
	}
}
	
contract TestEchidnaExample is EchidnaExample {
	address echidna_caller = msg.sender;
	// Echidna will fuzz the bytes8 gateKey
	function test_if_can_pass_the_gate(bytes8 gateKey) public {
		// Echidna will try to break the following property
		// it will try to find a sequence of transactions
		// that will set the entrant to something different
		// than address(0)
		assert(entrant == address(0));
	}
}
```

You can run this test with this command (if you have Echidna installed):
```
echidna-test relative-path-to-file.sol --contract TestEchidnaExample
```

For anyone that comes in the future, the `echidna-test` might have been changed to just `echidna`. I've seen a [PR in the Echidna repo to change the naming convention](https://github.com/crytic/echidna/pull/826). 

Echidna is reverting on the `gateThree` modifier. I know that from the corpus file generated after the fuzz run. If you are interested in that you can [do the exercises from echidna streaming series repository](https://github.com/crytic/echidna-streaming-series/tree/main/part2) (it will be merged into the [building secure smart contracts repository](https://github.com/crytic/building-secure-contracts) in the future, so the link might not work) and watch the [Echidna tutorial on youtube](https://www.youtube.com/watch?v=9P7sqE6hILM&t=1s). 

Before I run the Echidna with a larger number of fuzz runs I want to make sure that the problem is not in my test code and setup. At this point, I've run Echidna with `3_000_000` runs and it found nothing. It turns out that `bytes8` is a big number after all 🙈.

I will create another version of the `EchidnaExample` contract but with `bytes1` instead of the `bytes8` type. If my methodology is correct, Echidna should find a valid gate key fast...

And it actually is the case. Echidna is able to find the key. 

---
*Side note: Along the way, for the second time, I have found a bug in the tooling ([see: a bug in Foundry](https://github.com/foundry-rs/foundry/issues/3432)). [This time in Echidna / HEVM](https://github.com/crytic/echidna/issues/860).*

---

To find the correct key using Echidna, we could run it for a longer period or use [a new tool developed by Trail of Bits - Hybrid Echidna](https://blog.trailofbits.com/2022/12/08/hybrid-echidna-fuzzing-optik-maat/). It uses symbolic execution to assist Echidna in finding assertion violations. 

You can check [the installation instructions on its GitHub page](https://github.com/crytic/optik). 

Once you have it installed, you can clone my repo and run this command:

`hybrid-echidna src/levels/14-GatekeeperTwo/EchidnaExample.sol --contract TestEchidnaExample --config echidna_config.yaml`

Hybrid Echidna can find the key in ~2 minutes. 

I've run the test with the standard Echidna, and it wasn't able to find it in 50 minutes. 

![Hybrid echidna test output]((https://github.com/ChmielewskiKamil/ethernaut-foundry/blob/main/img/14-Hybrid-echidna-test-output.png?raw=true))

As you can see, the key contains some weird symbols: `^ CAN` and `RS`. This is due to the bug that I have found. The HEVM is opportunistically trying to decode bytes to string whenever possible. 

Cool! We got the key to the third gate. 

Let's pretend for a moment that we have the right key. Since this key is based on the `tx.origin` - Echidna caller, we could use `vm.prank` to make a call to the contract from that account. We can also set the caller to the address of Eve (she will be our attacker).

As of today (14.01.2023) Echidna is using the new version of HEVM that has the bug already fixed. I will run Echidna for a longer period of time to get the key and we will continue from there. 

Unfortunately after `20_000_000` runs Echidna couldn't find the key. 

This seemed like a good test for Manticore but unfortunately I couldn't get it to work due to technical issues 😞

Automatic tools got us this far. I've proven that it is possible to use Echidna to get through the third gate. I've tried encoding the key back to it's original form and with the help of ChatGPT I got this: `5e43414e246239205253212229df`. Doing it manually resulted in something completely different so we will have to check it out later in the exploit.

**Update:** the key mentioned above does not work.

Let's try the standard route now... with the XOR operator. 

### The standard route

I've read [the XOR operator wikipedia page](https://en.wikipedia.org/wiki/Exclusive_or) to understand it better. It turns out that the XOR operator is commutative. It means that `A XOR B == C` and `C XOR B == A` and `A XOR C == B`. 
Given `uint64(bytes8(keccak256(abi.encodePacked(msg.sender)))) ^ uint64(_gateKey) == type(uint64).max)` it seems relatively straightforward now. 

We want to calculate the `uint64(_gateKey`. It means that we can XOR the other two things in this equation.

The `uint64(bytes8(keccak256(abi.encodePacked(msg.sender)))) ^ type(uint64).max)` will be equal to our gate key `uint64(_gateKey)`.

## Potential attack scenario - hypothesis
*Eve is our attacker*

Eve can register herself as an entrant by making a call to the `GatekeeperTwo` contract from the attack contract. This call can be made from within the `constructor` to pass the first and the second gate. Eve can calculate the `_gateKey` by using the commutativity property of the "exclusive or" operator.

## Plan of the attack 

1. Eve deploys the `GatekeeperTwoAttack` contract.
2. The constructor of the attack contract takes the address of the `GatekeeperTwo` contract as an argument.
3. The constructor calculates the `uint(64)_gateKey` and casts it to `bytes8` as this is the type accepted by the `enter()` function in the `GateKeeperTwo` contract. 
4. The `_gateKey` is calculated from this equation: `uint64(bytes8(keccak256(abi.encodePacked(msg.sender)))) ^ type(uint64).max) = uint64(_gateKey)`
5. The `msg.sender` in this case is the address of the attack contract itself. So it will be calculated with the address of `this`.
6. From within the constructor a call to the `enter()` function will be made with the calculated `_gateKey` as an argument.
7. This will set the `tx.origin` (Eve) as an entrant in the `GatekeeperTwo` contract. 

## Proof of Concept - hypothesis test ✅ 

The hypothesis has been proven to be true. [You can see the full PoC unit test on GitHub.](https://github.com/ChmielewskiKamil/ethernaut-foundry/blob/main/test/14-GatekeeperTwo.t.sol)

Here is a simplified version of the exploit script:

```solidity
GatekeeperTwoAttack attackContract;
attackContract = new GatekeeperTwoAttack(
	address(gatekeeperTwoContract)
);
```

Here is the attack contract itself:
```solidity
contract GatekeeperTwoAttack {
    GatekeeperTwo victim;

    constructor(address _victim) {
        victim = GatekeeperTwo(_victim);
        uint64 gateKey = uint64(bytes8(keccak256(abi.encodePacked(this)))) ^
            type(uint64).max;

        victim.enter(bytes8(gateKey));
    }
}
```

## References
- [Official Solidity documentation - Inline Assembly](https://docs.soliditylang.org/en/v0.4.23/assembly.html)
- [Secureum Solidity 201](https://secureum.substack.com/p/solidity-201)
- [Secureum Security Pitfalls & Best Practices 101](https://secureum.substack.com/p/security-pitfalls-and-best-practices-101)
- [Trail of Bits - Echidna](https://github.com/crytic/echidna)
- [Trail of Bits - Manticore](https://github.com/trailofbits/manticore)
- [Pull request - Name change from echidna-test to echidna](https://github.com/crytic/echidna/pull/826)
- [Hybrid Echidna - GitHub](https://github.com/crytic/optik)