 SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "src/utilities/ERC20-08.sol";

contract NaughtCoinFactory is Level {

  function createInstance(address _player) override public payable returns (address) {
    return address(new NaughtCoin(_player));
  }

  function validateInstance(address payable _instance, address _player) override public view returns (bool) {
    NaughtCoin instance = NaughtCoin(_instance);
    return instance.balanceOf(_player) == 0;
  }
}
