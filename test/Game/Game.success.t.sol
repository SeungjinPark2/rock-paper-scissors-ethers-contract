// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Game.t.sol";

contract GameSuccessTest is GameTest {
    function test_initialization() public {
        (address fp1,,,) = game.player1();
        assertEq(p1, fp1);
        assertEq(1 ether, game.betSize());
    }

    function test_participate() public {
        _participate();
        (address fp2,,,) = game.player2();
        assertEq(p2, fp2);
    }

    function test_bet() public {
        _participate();
        _betP1();
        assertEq(betSize, address(game).balance);
        (,bool bd1,,) = game.player1();
        assertEq(true, bd1);

        _betP2();
        assertEq(betSize * 2, address(game).balance);
        (,bool bd2,,) = game.player2();
        assertEq(true, bd2);
    }

    function test_commit() public {
        _participate();
        _betP1();
        _betP2();

        (bytes32 _commit1, bytes32 _commit2) = _setCommit(RockScissorsPaperLib.Hand.Rock, RockScissorsPaperLib.Hand.Paper);

        _commitP1(_commit1);
        (,,bytes32 cc1,) = game.player1();
        assertEq(_commit1, cc1);

        _commitP2(_commit2);
        (,,bytes32 cc2,) = game.player2();
        assertEq(_commit2, cc2);
    }

    function test_reveal() public {
        _participate();
        _betP1();
        _betP2();
        (bytes32 _commit1, bytes32 _commit2) = _setCommit(RockScissorsPaperLib.Hand.Rock, RockScissorsPaperLib.Hand.Paper);
        _commitP1(_commit1);
        _commitP2(_commit2);

        _revealP1(RockScissorsPaperLib.Hand.Rock, salt1);
        (,,,RockScissorsPaperLib.Hand h1) = game.player1();
        assertEq(uint(h1), uint(RockScissorsPaperLib.Hand.Rock));
    
        _revealP2(RockScissorsPaperLib.Hand.Paper, salt2);
        (address fp2, bool bd2, bytes32 cc2, RockScissorsPaperLib.Hand h2) = game.player2();
    
        assertEq(address(p1).balance, 9 ether);
        assertEq(address(p2).balance, 11 ether);

        // check medium reset
        assertEq(fp2, p2);
        assertEq(bd2, false);
        assertEq(cc2, bytes32(0));
        assertEq(uint(h2), 0);
        assertEq(uint(game.phase()), uint(1));
    }
}
