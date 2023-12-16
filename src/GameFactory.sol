// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "src/Game.sol";
import "@openzeppelin/contracts/utils/Context.sol";

contract GameFactory is Context {
    uint16 immutable MIN_EXPIRE = 60 * 5;
    uint16 immutable MAX_EXPIRE = 60 * 60;
    mapping (address => uint) gameCount;
    event NewGame(address indexed creator, address game);

    function createGame(
        uint16 _expiration,
        uint _betSize
    )
        external
        returns (address _gameAddress)
    {
        require(
            _expiration >= MIN_EXPIRE
            && _expiration < MAX_EXPIRE
            , "Failed to create game, unavailable expiration"
        );
        require(_betSize > 0, "Failed to create game, invalid betSize");
        uint gameCountOfAddress = gameCount[_msgSender()];
        Game game = new Game{salt: bytes32(gameCountOfAddress)}(_msgSender(), _expiration, _betSize);
        gameCount[_msgSender()]++;
        _gameAddress = address(game);
        emit NewGame(_msgSender(), _gameAddress);
    }

    function getGameAddress(address _gameCreator, uint _expiration, uint _betSize, uint _gameNumber) external view returns (address game) {
        bytes memory _bytecode = getBytecode(_gameCreator, _expiration, _betSize);
        bytes32 hash = keccak256(
           abi.encodePacked(bytes1(0xff), address(this), _gameNumber, keccak256(_bytecode))
        );
        game = address(uint160(uint(hash)));
    }

    function getBytecode(address _gameCreator, uint _expiration, uint _betSize) public pure returns (bytes memory _bytecode) {
        bytes memory bytecode = type(Game).creationCode;
        _bytecode =  abi.encodePacked(bytecode, abi.encode(_gameCreator, _expiration, _betSize));
    }
}
