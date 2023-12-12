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
        uint _betSize,
        string _title
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
        uint storage gameCountOfAddress = gameCount[_msgSender()];
        Game game = new Game{salt: bytes32(gameCountOfAddress)}(_msgSender, _expiration, _betSize, _title);
        gameCountOfAddress++;
        _gameAddress = address(game);
        emit NewGame(_msgSender(), _gameAddress);
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
