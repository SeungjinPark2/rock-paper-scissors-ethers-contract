// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "src/Game.sol";

contract GameTestSuccess is Test {
    Game game;
    address p1;
    address p2;
    bytes32 salt1;
    bytes32 salt2;

    function setUp() public {
        game = new Game(5 * 60);
        p1 = address(111);
        p2 = address(222);
        vm.deal(p1, 10 ether);
        vm.deal(p2, 10 ether);
    }

    // init with proper values
    function test_Initialization() public {
        (address addr1,,) = game.player1();
        assertEq(addr1, address(0));
        assertEq(uint(game.phase()), uint(Game.Phase.Participate));
    }

    // test participate function
    function test_ParticipateSuccess() public {
        // first user situation
        vm.prank(p1);
        game.participate{value: 1 ether}();
        assertEq(game.betSize(), 1 ether);
        assertEq(uint(game.phase()), uint(Game.Phase.Participate));

        // second user situation
        vm.prank(p2);
        game.participate{value: 1 ether}();
        assertEq(uint(game.phase()), uint(Game.Phase.Commit));
    }

    // test commit funciton
    function test_CommitSuccess() public {
        test_ParticipateSuccess();
        salt1 = keccak256(abi.encodePacked(uint(1)));
        salt2 = keccak256(abi.encodePacked(uint(1)));
        bytes32 commit1 = keccak256(abi.encodePacked(RockScissorsPaperLib.Hand.Rock, salt1));
        bytes32 commit2 = keccak256(abi.encodePacked(RockScissorsPaperLib.Hand.Paper, salt2));

        // commit p1 with rock
        vm.prank(p1);
        game.commit(commit1);
        assertEq(uint(game.phase()), uint(Game.Phase.Commit));
        (, bytes32 _commit1,) = game.player1();
        assertEq(_commit1, commit1);

        // commit p2 with paper
        vm.prank(p2);
        game.commit(commit2);
        assertEq(uint(game.phase()), uint(Game.Phase.Reveal));
        (, bytes32 _commit2,) = game.player2();
        assertEq(_commit2, commit2);
    }

    // test reveal
    function test_RevealSuccess() public {
        test_CommitSuccess();
        vm.prank(p1);
        game.reveal(RockScissorsPaperLib.Hand.Rock, salt1);
        (,, RockScissorsPaperLib.Hand hand1) = game.player1();
        assertEq(uint(hand1), uint(RockScissorsPaperLib.Hand.Rock));

        vm.prank(p2);
        game.reveal(RockScissorsPaperLib.Hand.Paper, salt2);
        (,, RockScissorsPaperLib.Hand hand2) = game.player2();
        assertEq(uint(hand2), uint(RockScissorsPaperLib.Hand.Paper));
        assertEq(p2, game.winner());
        assertEq(address(game).balance, 0);
        assertEq(game.gameClosed(), true);
        assertEq(p2.balance, p1.balance + game.betSize() * 2);
    }

    function test_ClaimSuccess() public {
        test_ParticipateSuccess();
    }
}

