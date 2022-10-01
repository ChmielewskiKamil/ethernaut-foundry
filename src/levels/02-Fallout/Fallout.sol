// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "openzeppelin-contracts/math/SafeMath.sol";

contract Fallout {
    using SafeMath for uint256;
    mapping(address => uint) allocations;
    address payable public owner;

    // @audit-issue typo in the constructor name
    /**
     * because of that Fallout contract has no constructor
     * Fal1out function can be called by anyone
     */
    /* constructor */
    function Fal1out() public payable {
        owner = msg.sender;
        allocations[owner] = msg.value;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "caller is not the owner");
        _;
    }

    // @audit weird syntax mapping.add?
    // @audit-ok it is from safe math
    // @audit no event emitted on critical function
    function allocate() public payable {
        allocations[msg.sender] = allocations[msg.sender].add(msg.value);
    }

    // @audit no event emitted on critical function
    function sendAllocation(address payable allocator) public {
        require(allocations[allocator] > 0);
        allocator.transfer(allocations[allocator]);
    }

    // @audit no timelock -> possible unexpected withdrawal
    // @audit no event emitted on critical function
    function collectAllocations() public onlyOwner {
        msg.sender.transfer(address(this).balance);
    }

    function allocatorBalance(address allocator) public view returns (uint) {
        return allocations[allocator];
    }
}
