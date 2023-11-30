// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "src/GameFactory.sol";
import "src/Game.sol";

contract GameFactoryTest is Test {
    GameFactory gameFactory;
    address gameCreator;
    uint gameNumber = 0;
    uint16 expiration = 60 * 5;

    event NewGame(address indexed creator, address game);

    function setUp() public {
        gameFactory = new GameFactory();
        gameCreator = address(111);
        vm.deal(gameCreator, 10 ether);
    }

    function test_createGame() public {
        vm.expectEmit(true, false, false, true);
        emit NewGame(gameCreator, gameFactory.getGameAddress(expiration, gameNumber, gameCreator));
        vm.prank(gameCreator);
        address gameAddress = gameFactory.createGame{value: 1 ether}(gameNumber, expiration);
        (address player,,) = Game(gameAddress).player1();
        assertEq(player, gameCreator);
    }

    function test_getGameAddress() public {
        vm.prank(gameCreator);
        address gameAddress1 = gameFactory.createGame{value: 1 ether}(gameNumber, expiration);
        address gameAddress2 = gameFactory.getGameAddress(expiration, gameNumber, gameCreator);
        assertEq(gameAddress1, gameAddress2);
    }
}

