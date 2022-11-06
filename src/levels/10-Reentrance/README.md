# Ethernaut Level 10 - Re-entrancy

You can also read this
[on my blog](https://wizzardhat.com/ethernaut-level-10-re-entrancy/) 😎

## Objectives

- Steal all the funds from the contract!

## Contract Overview

The `Reentrance` contract works like a bank. This is a popular theme for the
Ethernaut contracts (see:
[Level 2 - Fallout](https://wizzardhat.com/ethernaut-level-2-fallout/)).
Contract users can send funds to any account that they specify. The owner of
such an account can later withdraw the money. It is also possible to check the
current balance of any account.

## Finding the weak spots

The first thing I did was to check if the use of the `SafeMath` is consistent
across the contract. You can
[check out the audit bookmarks](https://github.com/ChmielewskiKamil/ethernaut-foundry/blob/main/src/levels/10-Reentrance/Reentrance.sol)
that I've added to the `Reentrance` contract.

- I saw that `SafeMath` is not used inside the `withdraw()` function. It seems
  that underflow is not possible because of the previous `if` statement.

While working my way through the contract I saw a very similar thing to the one
in the
[previous challenge - King](https://wizzardhat.com/ethernaut-level-9-king/) - a
violation of the check-effects-interactions pattern. Whenever it is present,
there is a risk of re-entrancy.

- This time, however, this is a slightly different type of re-entrancy. Slither
  (Static analyzer from Trail of Bits) classifies reentrancies into five
  categories: `reentrancy-eth`, `reentrancy-no-eth`, `reentrancy-benign`,
  `reentrancy-events` and `reentrancy-unlimited-gas`. The re-entrancy with Ether
  is of the highest severity while the "unlimited-gas" one, is just an
  informational finding. It seems that in the `Reentrance` contract a bug of the
  highest severity is present.

If you recall, in the _King (level 9)_ challenge, there was also a re-entrancy
that was handling Ether. It was different though. The `King` contract has used
the `transfer()` function which prevents re-entrancies from happening because of
the gas stipend (2300 units). In the `Reentrance` contract, we have a low-level
`call` to handle Ether transfers. It is considered dangerous because it forwards
all the gas to the callee. If the called contract is malicious, this amount of
gas gives him plenty of space to operate and inflict some damage.

- There is also no 0 address check on the `donate()` function, which may lead to
  the loss of funds.

Case: Bob forgets to set the address in the `donate()` function. The default
value of the `address` type is used -> 0. Funds are lost.

## Potential attack scenario - hypothesis

_Eve is our attacker_

Because `balances` are updated after making the `call`, Eve can re-enter the
`withdraw` function, pass the `balances` check again and drain the contract
balance to zero by repeating the process.

## Plan of the attack

Given the `ReentranceAttack` contract that has:

- `sendDonation()` function that calls `donate()`
- `attack()` function that calls `withdraw()`
- `receive()` function that calls the `attack()`

1. Eve calls the `sendDonation()` function
   - it will make the address of the `ReentranceAttack` contract appear in the
     `balances` mapping
   - because of that the contract will be able to pass the check and re-enter
   - the more money Eve donates the better because she will be able to drain
     more money in one call.
2. Eve calls the `attack()` function to start the attack and cause a re-entrancy
3. Money should be drained???

It appears to me again that after you write something down, it is the moment
when you start the real thinking process. There are some new issues that I
haven't thought about before.

Because we haven't set any constraints on when the execution should stop, this
transaction will effectively be an endless loop. When taking gas constraints
into account this should eventually revert.

I think that at this point I need to write a simple test to see how the contract
is going to behave given different arguments. I am mainly interested to see how
the `Reentrance` contract balance and the `amount` donated affect the outcome.

### Initial testing

I've spent way too much time poking with the contract and trying out different
stuff. Now I know that it is necessary to set a goal, finish it and then proceed
with the next one.

It turns out that it is possible to underflow the `balances`. Here are the logs
that show the balance of the attack contract after the exploit:

![Integer underflow](https://github.com/ChmielewskiKamil/ethernaut-foundry/blob/main/img/10-underflow.png?raw=true)

This is the passing test that solves the challenge. As you can see the contract
balance underflowed and it is a very big number.

Right now I have no idea why this is happening. Let's explore further...

If we increase the verbosity of the test we see a little bit more:

![Test with increased verbosity](https://github.com/ChmielewskiKamil/ethernaut-foundry/blob/main/img/10-increased-verbosity.png?raw=true)

The `Reentrance` contract has `0.002` ether inside. As you can see the
`withdraw` function is called 3 times. 2 times it succeeds and the 3rd time is
an out-of-funds error.

I am not sure about this and I cannot find any information about it either but I
think that the out-of-fund error does not "panic/fail" or whatever we want to
call it. For example, if we set the gas limit lower. This test will fail:

![Out-of-gas exception](https://github.com/ChmielewskiKamil/ethernaut-foundry/blob/main/img/10-out-of-gas.png?raw=true)

I recall from Secureum that the transaction may revert if it runs out of gas or
is provided with invalid data. I suppose that the out-of-fund error is not
critical (just like you can send a transfer with 0 ether). I have not found any
source to back this hypothesis up. If this is true, it explains why the balance
of the `AttackContract` managed to underflow.

```solidity
// snippet ...

function withdraw(uint _amount) public {
	// 3rd call to withdraw
	// this passes because balances have not been upgraded
	if(balances[msg.sender] >= _amount) {
		// According to my hypothesis out-of-fund does not revert
		// this passes
		(bool result, ) = msg.sender.call{value: _amount}("");
		if (result) {
			_amount
		}
		// finally this is the only time balances are updated
		// but since the balance of msg.sender has been already drained
		// this underflows
		balances[msg.sender] -= _amount;
	}
}

// snippet...
```

I see a couple of problems in this logic, but I have no better explanation for
why the `balances` underflowed.

## Proof of Concept - hypothesis test ✅

Here is the attack contract
([full version here](https://github.com/ChmielewskiKamil/ethernaut-foundry/tree/main/src/levels/10-Reentrance/ReentranceAttack.sol))

```solidity
// snippet...

contract ReentranceAttack {
	Reentrance reentrance;

	constructor(address _reentranceContractAddress) public {
		reentrance = Reentrance(payable(_reentranceContractAddress));
	}

	function sendDonation() public payable {
		reentrance.donate{value: msg.value}(address(this));
	}

	function attack(uint256 _amountToWithdraw) public {
		reentrance.withdraw(_amountToWithdraw);
	}

	receive() external payable {
		reentrance.withdraw(msg.value);
	}
}
```

This is the simplified version of the unit test exploiting the contract:

```solidity
// snippet...

reentranceAttack.sendDonation{value: 0.01 ether}();

reentranceAttack.attack(0.01 ether);

// snippet...
```

Given the Ethernaut game setup (`0.001 ether` in the contract initially and
`0.001 ether` donated) exploiting the level is quite easy and cheap.

![Forge test gas report](https://github.com/ChmielewskiKamil/ethernaut-foundry/blob/main/img/10-gas-report-cheap.png?raw=true)

With just 3 calls we have managed to steal the funds. The gas cost was in the
worst case ~29k units of gas.

However, if the amount of Ether in the contract increases the cost of such an
attack is absurdly high. Let's give the contract 1 ether.

Running it with 1 ether overflows the stack :(
![Stack overflow](https://github.com/ChmielewskiKamil/ethernaut-foundry/blob/main/img/10-stack-overflow.png?raw=true)

We have to increase the attack amount as well (donation has to be higher to
withdraw more).

Parameters:

- `1 ether` inside the victim contract
- `0.01 ether` donated and `0.01 ether` withdrawn

![Forge test gas report with many calls](https://github.com/ChmielewskiKamil/ethernaut-foundry/blob/main/img/10-gas-report-expensive.png?raw=true)

As you can see increasing the amount of ether inside the contract requires much
more funds to successfully attack. It took 101 calls and over 800k units of gas.
Let's compare it:

- the value inside the victim contract was increased 500 times
- the funds required to attack were increased 10 times
- it increased the gas cost by over 28 times

It doesn't look this bad once I wrote it down. If we increase the parameters
further the gas cost will be much higher. Such a scenario will require much more
ether to attack. A flash loan could be used to exploit the contract.

## Recommendations

- Apply the checks-effects-interactions pattern. Making interactions before the
  state changes introduce an opening for the reentrancy attack.
- Use SafeMath for arithmetic operations.
- Use 0 address checks on functions that transfer funds.

## References

- You can also read this
  [on my blog](https://wizzardhat.com/ethernaut-level-10-re-entrancy/) 😎
