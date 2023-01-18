// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Setup} from "./Setup.sol";

contract EchidnaTest is Setup {
    function testTokenIsDeployed() public {
        assert(address(token) != address(0));
    }
}
