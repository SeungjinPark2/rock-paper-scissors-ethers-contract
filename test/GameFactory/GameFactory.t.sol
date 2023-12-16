// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "src/GameFactory.sol";
import "src/Game.sol";

contract GameFactoryTest is Test {
    GameFactory gameFactory = new GameFactory();
    address gameCreator;
    uint gameNumber = 0;
    uint16 expiration = 60 * 5;
    uint betSize = 1 ether;

    event NewGame(address indexed creator, address game);

    function setUp() public {
        gameCreator = address(111);
        vm.deal(gameCreator, 10 ether);
    }

    function test_createGame() public {
        vm.expectEmit(true, false, false, true);
        emit NewGame(gameCreator, gameFactory.getGameAddress(gameCreator, expiration, betSize, gameNumber));
        vm.prank(gameCreator);
        address gameAddress = gameFactory.createGame(expiration, betSize);
        (address player,,,) = Game(gameAddress).player1();
        assertEq(player, gameCreator);
    }

    function test_getGameAddress() public {
        vm.prank(gameCreator);
        address gameAddress1 = gameFactory.createGame(expiration, betSize);
        address gameAddress2 = gameFactory.getGameAddress(gameCreator, expiration, betSize, gameNumber);
        assertEq(gameAddress1, gameAddress2);
    }
}

