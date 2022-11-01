// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./Reentrance.sol";

contract ReentranceAttack {
    Reentrance reentrance;

    constructor(address _reentranceContractAddress) public {
        reentrance = new Reentrance(_reentranceContractAddress);
    }
}
