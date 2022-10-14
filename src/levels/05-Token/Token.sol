// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract Token {
    mapping(address => uint) balances;
    uint public totalSupply;

    constructor(uint _initialSupply) public {
        balances[msg.sender] = totalSupply = _initialSupply;
    }

    // @audit transfer does not revert -->
    // boolean value needs to be taken care of on the caller's end

    // @audit no 0 address check (address _to)
    function transfer(address _to, uint _value) public returns (bool) {
        // @audit-issue left side of the expression might underflow?
        // it means it will be greater than zero and pass the check
        require(balances[msg.sender] - _value >= 0);
        // @audit-issue if the above underflows
        // this will also underflow and wrap to the other side
        // of the uint256 range
        balances[msg.sender] -= _value;
        // @audit-issue this might possibly overflow?
        // if there is an underflow in the previous statement
        // increaseing balance by small value might overflow
        balances[_to] += _value;
        return true;
    }

    function balanceOf(address _owner) public view returns (uint balance) {
        return balances[_owner];
    }
}
