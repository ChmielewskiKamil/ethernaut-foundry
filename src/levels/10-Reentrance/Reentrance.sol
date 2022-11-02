// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "openzeppelin-contracts/math/SafeMath.sol";

contract Reentrance {
    //@todo - check if SafeMath is used in every
    // arithmetic operation
    //@follow-up - SafeMath is not used in withdraw()
    // potential underflow
    //@audit-ok - SafeMath is correclty used
    using SafeMath for uint256;
    mapping(address => uint) public balances;

    //@audit - no 0 address check
    //@audit-issue - funds may be lost when addr is not provided
    function donate(address _to) public payable {
        //@audit-ok - SafeMath is being used
        // potential overflow - not an issue
        balances[_to] = balances[_to].add(msg.value);
    }

    function balanceOf(address _who) public view returns (uint balance) {
        return balances[_who];
    }

    function withdraw(uint _amount) public {
        if (balances[msg.sender] >= _amount) {
            //@audit - violation of the CEI pattern
            //@audit-issue - potential high severity reentrancy with eth
            (bool result, ) = msg.sender.call{value: _amount}("");
            if (result) {
                _amount;
            }
            //@audit - SafeMath not used
            // potential integer underflow
            //@audit-ok - because of the "if" statement
            // it is not possible to underflow balances
            balances[msg.sender] -= _amount;
        }
    }

    receive() external payable {}
}
