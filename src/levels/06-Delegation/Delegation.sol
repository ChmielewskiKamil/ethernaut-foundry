// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract Delegate {
    address public owner;

    // @audit no 0 address check, if you forget to set the address
    // the contract might be locked forever
    constructor(address _owner) public {
        owner = _owner;
    }

    // @audit unprotected state modifying function
    function pwn() public {
        owner = msg.sender;
    }
}

contract Delegation {
    // @audit-ok the order of state variable declarations is ok
    address public owner;
    Delegate delegate;

    constructor(address _delegateAddress) public {
        delegate = Delegate(_delegateAddress);
        owner = msg.sender;
    }

    fallback() external {
        // @audit dangerous delegatecall with data provided by the user
        (bool result, ) = address(delegate).delegatecall(msg.data);

        // @audit-issue return value is not checked

        // @audit this does nothing(?) -> redundant code
        if (result) {
            // @follow-up there is no return statement
            this;
        }
    }
}
