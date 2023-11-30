// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "src/Game.sol";

contract GameFactory {
    uint16 MIN_EXPIR = 60 * 5;
    mapping (address => uint) gameCount;
    event NewGame(address indexed creator, address game);

    function createGame(uint _gameNumber, uint16 _expiration) external payable returns (address _gameAddress) {
        require(msg.value > 0, "Failed to create game, no balance for game");
        require(_expiration >= MIN_EXPIR, "Failed to create game, expiration is too short");
        Game game = new Game{salt: bytes32(_gameNumber), value: msg.value}(_expiration, msg.sender);
        gameCount[msg.sender]++;
        _gameAddress = address(game);
        emit NewGame(msg.sender, _gameAddress);
    }

    function getGameAddress(uint _expiration, uint _gameNumber, address _gameCreator) external view returns (address game) {
        bytes memory _bytecode = getBytecode(_expiration, _gameCreator);
        bytes32 hash = keccak256(
           abi.encodePacked(bytes1(0xff), address(this), _gameNumber, keccak256(_bytecode))
        );
        game = address(uint160(uint(hash)));
    }

    function getBytecode(uint _expiration, address _gameCreator) public pure returns (bytes memory _bytecode) {
        bytes memory bytecode = type(Game).creationCode;
        _bytecode =  abi.encodePacked(bytecode, abi.encode(_expiration, _gameCreator));
    }
}
