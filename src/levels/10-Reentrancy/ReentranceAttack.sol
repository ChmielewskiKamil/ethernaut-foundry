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
}
