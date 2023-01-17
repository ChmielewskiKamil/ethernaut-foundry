// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EchidnaExampleBytesOne {
    address public entrant;

    modifier gateThree(bytes1 _gateKey) {
        require(uint8(bytes1(keccak256(abi.encodePacked(msg.sender)))) ^ uint8(_gateKey) == type(uint8).max);
        _;
    }

    function enter(bytes1 _gateKey) public gateThree(_gateKey) {
        entrant = msg.sender;
    }
}

contract TestEchidnaExampleBytesOne {
    EchidnaExampleBytesOne echidnaExampleBytesOne;

    event Entrant(address entrant);
    event ContractAddress(address contractAddr);
    event GateKey(bytes1 gateKey);
    event LastByteOfSender(bytes1 senderAddress);
    event KeccakOfTheContract(bytes32 contractAddr);
    event KeccakConvertedToBytes(bytes2 contractAddr);
    event XorOutput(bytes1 xorOutput);
    event MaxType(bytes1 maxType);

    constructor() {
        echidnaExampleBytesOne = new EchidnaExampleBytesOne();
    }

    function test_if_can_pass_the_gate(bytes1 gateKey) public {
        emit Entrant(echidnaExampleBytesOne.entrant());
        try echidnaExampleBytesOne.enter(gateKey) {
            emit Entrant(echidnaExampleBytesOne.entrant());
            emit ContractAddress(address(this));
            emit GateKey(gateKey);
            emit LastByteOfSender(bytes1(keccak256(abi.encodePacked(msg.sender))));
            emit KeccakOfTheContract(keccak256(abi.encodePacked(address(this))));
            emit KeccakConvertedToBytes(bytes2(keccak256(abi.encodePacked(address(this)))));
            emit XorOutput(bytes1(keccak256(abi.encodePacked(address(this)))) ^ gateKey);
            emit MaxType(bytes1(type(uint8).max));
            // assert(echidnaExampleBytesOne.entrant() == address(0));
        } catch (bytes memory error) {
            // assert(true);
        }
    }
}
