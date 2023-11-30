// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "src/Game.sol";

contract GameFactory {
    uint16 MIN_EXPIR = 60 * 5;
    mapping (address => uint) gameCount;
    event NewGame(address indexed creator, address game);

    function createGame(uint _gameNumber, uint16 _expiration) external payable {
        require(_expiration >= MIN_EXPIR, "Failed to create game, expiration is too short");
        Game game = new Game{salt: bytes32(_gameNumber)}(_expiration);
        gameCount[msg.sender]++;
        emit NewGame(msg.sender, address(game));
    }
    /*
    * _bytecode = abi.encodePacked(
    *     type(Game).creationCode,
    *     abi.encode(arg)
    * )
    */
    function getGameAddress(bytes memory _bytecode, uint _gameNumber) external view returns (address game) {
        bytes32 hash = keccak256(
           abi.encodePacked(bytes1(0xff), address(this), _gameNumber, keccak256(_bytecode))
        );
        game = address(uint160(uint(hash)));
    }
}
