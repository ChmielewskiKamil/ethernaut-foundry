// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract Vault {
    bool public locked;
    // @audit nothing is private on the blockchain
    // passwords especially
    bytes32 private password;

    constructor(bytes32 _password) public {
        locked = true;
        password = _password;
    }

    // @audit-issue password can be accessed by looking at
    // the contract storage slots
    // it is not safe
    function unlock(bytes32 _password) public {
        if (password == _password) {
            locked = false;
        }
    }
}
