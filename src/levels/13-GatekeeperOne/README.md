# Ethernaut Level 13 - GatekeeperOne

You can also read this
[on my blog](https://wizzardhat.com/ethernaut-level-13-gatekeeperone/) 😎

## Objectives

- Make it past the gatekeeper!

Register as an entrant -> change the `entrant` to your address.

## Contract Overview

To reach the objective and `enter` the `GatekeeperOne` contract it is necessary
to get past the three gates. The first two gates look relatively easy to pass.
The third one, however, looks a little bit more complicated. Let's investigate
them...

## Finding the weak spots

In the GatekeeperOne contract, all of the modifiers have correct execution
paths. They either revert or end with the underscore `_`. There is no "cheesy"
way to complete the challenge. To `enter` the contract we need to satisfy the
requirements in the modifiers.

### The first gate

To satisfy the `msg.sender =! tx.origin` check we need to call the
`GatekeeperOne` contract from another contract. This is the same thing as in the
[Telephone - level 4](https://wizzardhat.com/ethernaut-level-4-telephone/)
challenge.

### The second gate

To pass through the second gate we need to understand what the `gasleft()`
function does. It
[returns the remaining gas](https://docs.soliditylang.org/en/v0.8.3/units-and-global-variables.html#block-and-transaction-properties)
in a transaction as a uint256 number. This information combined with the fact
that modifiers are executed at the very beginning of the lifetime of a function
call is enough to pass the second gate. The `gasleft()` executed before any
expensive logic is used will probably return the gas supplied in the
transaction. To pass the second gate the attacker will have to supply any amount
of gas that is divisible by `8191` without remainder.

### The third gate

The code inside this modifier looks a little bit intimidating. There are a lot
of weird conversions between `uint` types. There is also the mysterious
`bytes8 _gateKey`. 8 bytes is 64 bits, maybe that will be useful. Where to
start? Do we need to guess the `_gateKey`?

We need a lead to start with. Maybe a `constant` value that we can hook to and
guess the `_gateKey`?

If you look at the third `require` inside the `gateThree`:

```solidity
uint32(uint64(_gateKey)) == uint16(tx.origin)
```

It appears that `tx.origin` is used here. It will be the address of the person
that initiated the transaction. I believe that we can work our way backwards
from that and figure out what the `_gateKey` is.

It is necessary to understand what happens when you convert a larger integer
type to a smaller one. In the case of downcasting (converting to the smaller
type), the higher-order bits will be cut off (part of the number on the left).

In the opposite case, when you convert to a larger type, padding will be added
to the left of the higher-order bits (zeroes will be added at the front).

---

_Disclaimer: The following section contains a technical flaw. The affected lines
are marked with bolded text (the explanation is in the brackets). I think this
is still worth reading because you will get a better understanding of the final
solution and why it works. Thanks!_

---

As a little exercise let's work our way backwards without writing any code.

The `tx.origin` is a 20 bytes address (160 bits). It is being downcasted to
`uint16`. It will be equal to the last 16 bits of the attacker's address. It
will be a number with 16 digits like `1234567891234567`. To make it more concise
I will write it down as a `1...16`.

Look at the table below. As I have mentioned before the
`uint64(bytes8 _gateKey)` is just a `uint64` number. It is being downcasted to
`uint32`. The higher-order bits will be cut off and we will be left with the
last 32 bits.

How to make a 32-bit number equal to a 16-bit number? You have to add 16 zeroes
to the front of the 16-bit number. (**This is wrong - the opposite is true ->
you have to make the first 16 digits of the larger number zeroes**)

`0x123` is equal to `0x000123`

| Where is it?  | Code on the left           | Code on the right   | Value on the left   | Value on the right |
| ------------- | -------------------------- | ------------------- | ------------------- | ------------------ |
| 3rd `require` | `uint32(uint64(_gateKey))` | `uint16(tx.origin)` | (16zeroes)...1...16 | 1...16             |

I thought that we will need to go through every single one of the `require`
blocks but I think that we will be able to calculate the `_gateKey` right away.

How to convert the 32-bit number to the 64-bit number so that they are still
equal? You have to add 32 zeroes to the front of the 32-bit number. (**This is
also wrong -> again... to make those numbers equal you have to zero out the
first 32 digits of the larger number**)

This is our `_gateKey` as `uint64`: `(48zeroes)...1...16`.

In case you are wondering: We had `16` zeroes and `16` digits and now we add 32
zeroes so that we have `48` zeroes total and `16` digits (altogether 64 bits).

I am not sure whether this will be equal to the bytes8 right away so let's find
out...

We could use the deployment script from the previous challenge and interact with
the contract this way. There is one downside to this approach. There are still
two modifiers (gate one and gate two) that we would have to satisfy. Because we
are in the sandbox environment we can freely comment out `gateOne` and `gateTwo`
in the `enter` function and check if the third modifier `gateThree` reverts.

This time, however, I think that writing an MVP PoC will be much simpler and
simply worth our time.

Let's form the hypothesis...

## Potential attack scenario - hypothesis

This hypothesis will be lengthy. Let's split it into three distinct parts that
have to be true.

_Eve is our attacker_

Eve can register herself as an entrant in the `GatekeeperOne` contract by
calling the `enter` function from the `GatekeeperOneAttack` contract.

- A call from the contract will satisfy the criteria of the first gate.
- To pass the second gate Eve will supply the call with an amount of gas that is
  a multiple of `8191`.
- To pass the third gate Eve can reverse the `_gateKey` from the third `require`
  block. The key is equal to `(48 zeroes)` the + last `16` digits from the
  `tx.origin` address (Eve).

## Plan of the attack

1. Eve creates the `GatekeeperOneAttack` contract
   - The contract contains an `attack()` function which will make a call to the
     `enter()` function on the `GatekeeperOne` contract.
   - The amount of gas for this call will be `8191` units.
   - The `data` will be the last 16 digits of Eve's address with additional 48
     zeroes added to it at the front. It will be converted to the `bytes8` type.
2. Eve should successfully register herself as an entrant.

## Proof of Concept - hypothesis test ❌

There is a problem :>

The transaction kept on reverting so I have added revert strings to the
`GatekeeperOne` contract to know what is going on.

It turns out that the hypothesis about the second gate was wrong. Supplying the
call with `8191` units of gas does not do the trick. I've experimented with
different numbers because I knew that the transaction itself needs some gas. I
will try to make a `for` loop to burn through gas and call the `GatekeeperOne`
contract only if the amount is just right...

I've spent two hours trying to figure this out but it always reverts. I guess I
have to take a break and come back to it with a fresh mind.

---

It turns out that I was iterating correctly but my method of obtaining the key
was wrong and the `revert` was triggered further down the line (reverts were
piling up). There were several reasons...

### How to pass the third gate?

First thing first you have to change one line in the test setup. You need to
start the prank with `tx.origin` instead of Eve.

```solidity
vm.startPrank(tx.origin);
```

The `tx.origin` to pass the third gate is the `GatekeeperOneTest` contract
itself. It took me a very long time to figure this out (it is hardcoded in
Foundry - every test contract has the same `tx.origin`)

The `tx.origin` works weirdly in Foundry. I've read in the docs that you can
specify two addresses in the `startPrank` to set the origin but it does not
work. Let's assume that Eve is the `tx.origin`.

#### What the hell is bit masking and how to think about hex numbers

This is the first time that I have watched the
[walkthrough of the challenge](https://www.youtube.com/watch?v=AUQxXJiqLF4)...
And I still couldn't understand it fully. The solution is something called
"bitmasking". I experimented with it for a moment and it finally clicked.

Let's start from the beginning. To understand what bitmasking is I needed to
change the way how I was perceiving hexadecimal numbers.

Each hex digit represents half a byte (a nibble). A byte is 8 bits. It means
that each hex digit is equal to 4 bits. For example, `0xF` is equal to `1111` or
`0xFF` is equal to `1111 1111`. Please read the "Masking bits to 0" section of
[this Wikipedia article](<https://en.wikipedia.org/wiki/Mask_(computing)>). In
short - you add a mask to a number and:

- if you add `0` or you add anything to `0` the result will be `0` (technically
  it's not adding it's _AND'ing_ with `&` operator)
- if you add `1` to `1` it will remain unchanged

The previous example of `0xF` being `1111` is important. Let's do a simple
exercise.

How to zero out the first byte of a number `0x1234` and leave the second byte of
this number unchanged?

You can apply a mask `0x00FF`! Let's explore how this works under the hood:

```
This is the number in hex -> binary representation
0x1234 == 0001001000110100
This is the mask
0x00FF == 0000000011111111

0x1234 & 0x00FF will look like this
number: 0001001000110100
mask:   0000000011111111
        ----------------
result: 0000000000110100
```

If you take the result and place it in
[the converter](https://www.rapidtables.com/convert/number/hex-to-binary.html)
you will get the result: `0x34` which is equal to `52` in decimal. The actual
result is `0x0034` but this is the same as `0x34`!

Now that we understand this part let's get back to the third gate. My initial
thinking was wrong. I thought that to make two hex numbers equal you have to add
zeroes to the smaller type number. The solution is the exact reverse situation.
You have to mask the initial digits on a larger type number so that they are
zeroes. This is the case because we are cutting the higher-order bits when
downcasting. So we can either cut them or zero them out.

Let's say you have a 4-byte number `0x12345678` Now you can perform two
different operations: a) you downcast it to 2-byte type -> result: `0x5678`
(higher-order bits are cut-off) b) you apply the mask `0x0000FFFF` -> result:
`0x00005678`

In both cases the number are equal: `0x5678 == 0x00005678` You can verify and
play with this in
[the hex converter](https://www.rapidtables.com/convert/number/hex-to-binary.html?x=0x123).

#### Passing the three conditions

The gate key is 8 bytes long. As we previously said each hex digit represents
half a byte. We can think of the gate key as a 16-digit number
`0x0000000000000000`.

Let's look at the first condition:
`uint32(uint64(_gateKey)) == uint16(uint64(_gateKey))`. What does it mean?
Please recall that with downcasting to a smaller type the higher-order bits are
being cut off. It means that we want the last `4` bytes (32 bits) of the key to
be equal to the last `2` bytes (16 bits). Let's illustrate the problem...

```
4 bytes number (8 nibbles):     0xXXXXXXXX
2 bytes number (4 nibbles):     0xXXXX

How to make them equal?         ----------
We can apply the mask
to the first number           & 0x0000FFFF

After that:
4 bytes number:                 0x0000XXXX
2 bytes number:                 0xXXXX

They are equal:
0x0000XXXX == 0xXXXX
```

There is still one small thing that needs to be done. We need to apply the mask
to the gate key, not the first number. The number in the example was 4 bytes
long and the gate key is 8 bytes long. Our mask needs to be bigger. The compiler
won't let us apply a mask of a different size than the number itself.

```
8 bytes gate key (16 nibbles): 0xXXXXXXXXXXXXXXXX

Let's create the same mask
but we also need to count
additional nibbles
                               ------------------
8 bytes mask:                & 0x000000000000FFFF

The result will be the same:   0x000000000000XXXX

0xXXXX == 0x0000XXXX == 0x000000000000XXXX
```

Let's look at the second condition:
`uint32(uint64(_gateKey)) != uint64(_gateKey)` What does it mean?

Right now our key (with the mask applied) consists of 12 zeroes and 4 digits at
the very end. It does not matter which sizes of the key we would compare
`uint32`, `uint16` or `uint64`. Because the mask makes everything at the front
equal to `0` so we are effectively comparing just the last 2 `bytes.`

Let's test this with the Foundry logging system:

```solidity
emit log_named_uint(
	"part two - uint32: ",
	uint32(uint64(gateKeyPartOne))
);

emit log_named_uint(
	"part two - uint64: ",
	uint64(gateKeyPartOne)
);
```

If you run the test script with the gate key from the previous example the
output will be the same. The `uint64` version of the key `==` the `uint32`
version (in my case both equal to `60018` in decimal)

How can we make them different? We can simply "mask on" (mask with `1` -> value
unchanged) some bits at the front. The first check will still pass because
higher-order bits are being cut off so it does not influence anything. Let's
test this:

```
8 bytes gate key (16 nibbles): 0xXXXXXXXXXXXXXXXX
Our new mask (notice 1st F): & 0xF00000000000FFFF
                               ------------------
The result:                    0xX00000000000XXXX
```

Funnily enough, if you run the attack script with the following key (and the
mask):

```solidity
bytes8 gateKeyPartTwo = bytes8(uint64(uint160(tx.origin))) &
	0xF00000000000FFFF;
```

It will pass the test and solve the challenge. It passes the third condition for
the same reason as the second one.

We are comparing only lower-order bits and the higher-order ones with the new
mask applied are cut off.

```solidity
uint32(uint64(_gateKey)) == uint16(tx.origin)
```

## Hypothesis test

Let's bring back the hypothesis:

1. A call from the contract will satisfy the criteria of the first gate. ✅
2. To pass the second gate Eve will supply the call with an amount of gas that
   is a multiple of `8191`. ✅
3. To pass the third gate Eve can reverse the `_gateKey` from the third
   `require` block. The key is equal to `(48 zeroes)` the + last `16` digits
   from the `tx.origin` address (Eve). ❌

The first two have been proven to be correct. The third hypothesis is a little
bit funny because now when I look at it it is not far from being true. If we
divide `48` zeroes (bits) by `4` (nibble size) we get 12. This is the exact
number of zeroes that we had in the first mask. The final solution is just
slightly different from that with the additional `F` at the front.

You can find the full version of the
[PoC unit test here](https://github.com/ChmielewskiKamil/ethernaut-foundry/blob/main/test/13-GatekeeperOne.t.sol).

## The anatomy of an attack function

I think that the gas brute forcing mechanism also needs some additional
explanation. I've seen a lot of theory crafting around it. Let's look at the
`attack()` function. As always you will find the code in my
[GitHub repository](https://github.com/ChmielewskiKamil/ethernaut-foundry/tree/main/src/levels/13-GatekeeperOne/GatekeeperOneAttack.sol):

```solidity
function attack(bytes8 _gateKey) public {
	for (uint256 i = 0; i <= 211; i++) {
		try gatekeeperOne.enter{gas: i + 8191 * 3}(_gateKey) {
			break;
		} catch {}
	}
}
```

Let's start with the `i<=211`. Why `211`? In every write-up this number is
different. This is because of the way that you constructed your exploit. It will
use a different amount of gas for everyone. I've tested this extensively and
anything smaller than `211` does not work and the transaction reverts. It is
just iterating `211` times until it finds the number that is divisible by
`8191`.

Now the `8191 * 3` part. To my understanding, it is just the basic gas stipend
for a transaction. It has to be bigger than `21000` units of gas and
`8191 * 3 = 24573` which is `>21000`.

## Conclusion

This particular challenge was hard for me. It took me a couple of days to figure
out the right answer and to understand it fully.

One funny thing that I have discovered is that there is no write-up (or at least
I haven't found it) that explains the final mask well. They all apply something
like this `0xFFFFFFFF0000FFFF`. Everyone just copies this mask and takes it for
granted.

## References

- [Ethernaut CTF - Gatekeeper 1 - D-Squared](https://www.youtube.com/watch?v=AUQxXJiqLF4)
- [Bitmasking - Wikipedia](<https://en.wikipedia.org/wiki/Mask_(computing)>)
- [Hex - decimal converter](https://www.rapidtables.com/convert/number/hex-to-binary.html)
- You can also read this
  [on my blog](https://wizzardhat.com/ethernaut-level-13-gatekeeperone/) 😎
