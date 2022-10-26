# Ethernaut Level 8 - Vault

You can also read this
[on my blog](https://wizzardhat.com/ethernaut-level-8-vault/) 😎

## Objectives

- Unlock the vault!

## Contract Overview

Access to the `Vault` contract is protected by a password. It is set during
contract construction. The password string is saved as `bytes32` in the private
variable `password`. The state of the `Vault` is represented by the boolean flag
`locked`. The contract is locked by default (`locked` is equal to true) and the
goal is to change it to `false`.

## Finding the weak spots

Data on the blockchain is public and accessible to everyone. This is the reason
why it is not recommended to store any sensitive information or data on a public
ledger. Secret passwords fall into this group.

- The `password` to the `Vault` contract is not hidden at all. The `private`
  visibility specifier gives a fall sense of security and privacy.
- Private state variables (and functions) are only hidden from other contracts.
  They are visible in the contracts in which they are defined. Any off-chain
  component can still query contracts storage and access specific storage slot
  values.

It is possible to interact with the contract using the cast `cli` provided by
the Foundry.

### How to deploy a smart contract using forge create

The cast is used to perform RPC calls from your command line. The easiest way to
quickly interact with a contract is to deploy it to the local `anvil` chain
(also a Foundry feature) and play with it with the `cast`. To deploy the `Vault`
contract first we need to have a place to which we can deploy.

Spin up your local blockchain in one terminal using the `anvil` (`-b` flag
represents block time - set it to whatever you want)

```shell
anvil -b 5
```

Now things get a little bit complicated when using just the command line. To
deploy the `Vault` contract we need to pass the `password` as an argument to the
constructor. This password needs to be of type `bytes32`. For that, we will use
the `cast --format-bytes32-string` command.

Let's convert a string `"Example secret password"` to `bytes32` using the
`cast`.

```shell
cast --format-bytes32-string "Example secret password"
```

To save us a little headache in the future we can save this to a bash variable.
Remember not to add spaces before or after the `=` sign.

```shell
password=$(cast --format-bytes32-string "Example secret password")
```

To test that everything works fine you can print it in the console.

```shell
echo $password
```

Now we need an account from which we will deploy. Anvil is nice enough and
provides us with such account. Scroll up in the terminal where the chain is
deployed or spin up a new one and copy one of the accounts public keys. I will
use the first one (number 1).

![Anvil accounts](https://github.com/ChmielewskiKamil/ethernaut-foundry/blob/main/img/08-Anvil-accounts.png?raw=true)

Let's save it to the variable the same way we saved the password.

```shell
deployer=0x70997970c51812dc3a010c7d01b50e0d17dc79c8

# Let's test it
echo $deployer

# should return your deployer address
# 0x70997970c51812dc3a010c7d01b50e0d17dc79c8
```

Finally, we are ready to deploy the `Vault` contract. We will use the
`forge create` command for that with the `--unlocked` flag. It means that we are
using one of the unlocked accounts. We will pass the password with the
`--constructor-args` and the deployer address via `--from` the flag.

```shell
forge create Vault --unlocked --from $deployer --constructor-args $password
```

Save the address of the deployed contract to a variable.

```shell
contractAddr=0x8464135c8F25Da09e49BC8782676a84730C318bC
```

Now we can interact with the deployed `Vault` contract. Let's see what is inside
the storage of the contract. Please note that anyone can do this to any contract
that is already deployed.

#### How does EVM store state variables

Recall, that the Storage in EVM is implemented as a key <-> value store between
256-bit keys and 256-bit values. These 256-bit values are also known as "words".
256-bit is 32 bytes. It means that each storage slot can fit 32 bytes of data.
Variables are put into storage in the order of declaration. In the `Vault`
contract, there are two state variables: `bool public locked` and
`bytes32 private password`.

Here is a [great video](https://www.youtube.com/watch?v=Gg6nt3YW74o) from Smart
Contract Programmer about the storage layout. In the picture below you can see
the graphical representation of the alignment of variables inside the storage
slots. As you can see every slot contains a value in hex. After `0x` there are
64 digits. They are called nibbles, they represent half a byte (four bits). The
`uint256` is 32 bytes so it fills all of the 64 nibbles. 20 bytes `address` ->
40 nibbles and 1 byte `boolean` -> 2 nibbles.

![Storage - Smart Contract programmer](https://github.com/ChmielewskiKamil/ethernaut-foundry/blob/main/img/08-Smart-Contract-Programmer-Storage.png?raw=true)

Coming back to the `Vault` contract... The `boolean` variable will need 1 byte
of storage space and the `bytes32` variable will take the whole word. Padding
will be added on the left of the boolean and it will be filled with zeroes -
this will be the storage slot number `0`. The first slot will be occupied by the
`password`. This is a visual representation of this situation in contracts
storage:

| key (slot number) | value      |
| ----------------- | ---------- |
| 0                 | 0x000...01 |
| 1                 | 0x457...00 |

### How to read storage slots using Cast

Now that we know what we want to access we can easily do it using the
`cast storage` command. It takes two parameters: the address of the deployed
contract and the slot number that we want to access.

```shell
passwordFromStorage=$(cast storage $contractAddr 1)
```

If you did everything correctly now you can test it with
`echo $passwordFromStorage`. It should match the value from the
`echo $password`.

Before we interact with the contract let's check the value in slot number `0`
(use the same method as for the password). There should be 63 zeroes and `1` at
the very end. It means that the `boolean` is set to true.

### How to call smart contract functions from cli using cast send

To send a transaction to our local blockchain (or mainnet or testnet) we can use
the `cast send` command. We need to provide it with the function signature from
the contract that we want to interact with. I've covered function signatures in
the
[Delegation challenge](https://wizzardhat.com/ethernaut-level-6-delegation/).
Please refer to it if you have any doubts.

```shell
cast send $contractAddr --from $deployer "unlock(bytes32)" $passwordFromStorage
```

This function should successfully change the `boolean` flag from `true` to
`false`. Let's check this...

```shell
cast storage $contractAddr 0
```

This should result in a number that consists only of zeroes. We have
successfully unlocked the `Vault`.

There is still one thing to remember. After dealing with sensitive data like
private keys, mnemonics etc. even for the testnet acounts, remember to clean
your terminal session history.

```shell
history -c
```

After this, close your terminal and the history file is deleted.

## Potential attack scenario - hypothesis

_Eve is our attacker_

Eve can query the secret password from the appropriate storage slot via a remote
procedure call (RPC).

## Plan of the attack

1. Eve looks at the order of declaration of state variables in the contracts
   source code.
2. Eve determines which storage slot will be occupied by the password.
3. Eve performs an RPC call to read the password from the storage.
   - this can be done through cli
   - or through a script using any library that allows interaction with the
     blockchain
4. Eve can now make a call to the `unlock()` function passing the `password` as
   the argument.
5. The `Vault` contract is unlocked.

## Proof of Concept - hypothesis test ✅

Technically a proof of concept can be anything that proves the existence of a
bug. This is usually done through
[a unit test, exploit on a fork or for game theoretic bugs - a simulation](https://joranhonig.nl/3-ways-to-write-a-proof-of-concept/).
The cli commands presented in the previous paragraphs could also be a form of
proof of concept. They allowed us to quickly illustrate the problem. They are
not the preferred way to do that though. When you write a unit test that
exploits a vulnerability, it can be usually incorporated into the codebase and
will inform the dev team whether the issue has been successfully fixed or not.
Additionally, it may prevent a similar issue from happening in the future. Let's
write a unit test then...

Please keep in mind that some unit tests that illustrate exploits are very
specific and to large extent, they depend on the context so they don't offer
much value in terms of the overall code quality and coverage.

Here is a simplified version of the exploit in Foundry
([Full version accessible here](https://github.com/ChmielewskiKamil/ethernaut-foundry/blob/main/test/08-Vault.t.sol)):

```solidity
bytes32 passwordFromStorage = vm.load(
	address(vaultContract),
	bytes32(uint256(1))
);

(bool success, ) = address(vaultContract).call(
	abi.encodeWithSignature("unlock(bytes32)", passwordFromStorage)
);
require(success, "Transaction failed");
```

Here are the logs from the exploit:

![Test logs](https://github.com/ChmielewskiKamil/ethernaut-foundry/blob/main/img/08-test-logs.png?raw=true)

We can also increase the verbosity to see the traces and check what is happening
with the `bool` variable `locked`:

![Vauls is opened](https://github.com/ChmielewskiKamil/ethernaut-foundry/blob/main/img/08-vault-locked-false.png?raw=true)

The `VaultFactory` is validating the instance by reading the value from the
`bool` locked -> it's false.

## Recommendations

- Sensitive information should not be stored on the blockchain in raw form. One
  way to mitigate the issue would be to store the hash of the password with a
  `salt` added to it to obfuscate it. Later when a user would like to unlock the
  `Vault` he would use a function that calculates the hash from the password
  that he submitted, adds `salt` to it and checks if it matches with the one
  stored in the storage. This way it would be impossible to just copy the
  password from storage because to calculate it you need both the `salt` and the
  password itself.

## References

- [Ethernaut level 6 - Delegation](https://wizzardhat.com/ethernaut-level-6-delegation/)
- [Smart Contract Programmer - Accessing private data](https://www.youtube.com/watch?v=Gg6nt3YW74o)
- [Joran Honig - 3 ways to write a proof of concept](https://joranhonig.nl/3-ways-to-write-a-proof-of-concept/)
