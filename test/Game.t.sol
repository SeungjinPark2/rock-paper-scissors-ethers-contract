// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "src/Game.sol";

contract GameTest is Test {
    Game game;
    address p1;
    address p2;
    bytes32 salt1;
    bytes32 salt2;
    uint16 expiration = 5 * 60;

    event PhaseChanged(Game.Phase phase);
    event Winner(address winner, uint prize);
    event UpdatePlayer(address player, bytes32 commit, RockScissorsPaperLib.Hand hand);

    function setUp() public {
        p1 = address(111);
        p2 = address(222);
        vm.deal(p1, 10 ether);
        vm.deal(p2, 10 ether);
        vm.prank(p1);
        game = new Game{value: 1 ether}(expiration, p1);
        salt1 = keccak256(abi.encodePacked(uint(1)));
        salt2 = keccak256(abi.encodePacked(uint(1)));
        setCommit(RockScissorsPaperLib.Hand.Rock, RockScissorsPaperLib.Hand.Paper);
    }

    function setCommit(RockScissorsPaperLib.Hand _hand1, RockScissorsPaperLib.Hand _hand2)
        internal
        view
        returns (bytes32 _commit1, bytes32 _commit2)
    {
        _commit1 = keccak256(abi.encodePacked(_hand1, salt1));
        _commit2 = keccak256(abi.encodePacked(_hand2, salt2));
    }

    // init with proper values
    function test_Initialization() public {
        (address addr1,,) = game.player1();
        assertEq(addr1, p1);
        assertEq(uint(game.phase()), uint(Game.Phase.Participate));
    }

    // test participate function
    function test_ParticipateSuccess() public {
        assertEq(game.betSize(), 1 ether);
        assertEq(uint(game.phase()), uint(Game.Phase.Participate));

        // second user situation
        vm.expectEmit(false, false, false, true);
        emit PhaseChanged(Game.Phase.Commit);
        vm.prank(p2);
        game.participate{value: 1 ether}();

        assertEq(uint(game.phase()), uint(Game.Phase.Commit));
    }

    // test commit funciton
    function test_CommitSuccess() public {
        test_ParticipateSuccess();
        (bytes32 _commit1, bytes32 _commit2) = setCommit(
            RockScissorsPaperLib.Hand.Rock,
            RockScissorsPaperLib.Hand.Paper
        );

        // commit p1 with rock
        vm.expectEmit(false, false, false, true);
        emit UpdatePlayer(p1, _commit1, RockScissorsPaperLib.Hand.Empty);
        vm.prank(p1);
        game.commit(_commit1);
        assertEq(uint(game.phase()), uint(Game.Phase.Commit));
        (, bytes32 __commit1,) = game.player1();
        assertEq(__commit1, _commit1);

        // commit p2 with paper
        vm.prank(p2);
        game.commit(_commit2);
        assertEq(uint(game.phase()), uint(Game.Phase.Reveal));
        (, bytes32 __commit2,) = game.player2();
        assertEq(__commit2, _commit2);
    }

    // test reveal
    function test_RevealSuccess() public {
        test_CommitSuccess();
        vm.prank(p1);
        game.reveal(RockScissorsPaperLib.Hand.Rock, salt1);
        (,, RockScissorsPaperLib.Hand hand1) = game.player1();
        assertEq(uint(hand1), uint(RockScissorsPaperLib.Hand.Rock));

        vm.expectEmit(false, false, false, true);
        emit Winner(p2, 2 ether);
        vm.prank(p2);
        game.reveal(RockScissorsPaperLib.Hand.Paper, salt2);
        (,, RockScissorsPaperLib.Hand hand2) = game.player2();
        assertEq(uint(hand2), uint(RockScissorsPaperLib.Hand.Paper));
        assertEq(p2, game.winner());
        assertEq(address(game).balance, 0);
        assertEq(game.gameClosed(), true);
        assertEq(p2.balance, p1.balance + game.betSize() * 2);
    }

    // p1 reveals but p2 does not
    function test_ClaimSuccessOnRevealPhase() public {
        test_CommitSuccess();
        vm.prank(p1);
        game.reveal(RockScissorsPaperLib.Hand.Rock, salt1);

        vm.warp(block.timestamp + expiration * 2);
        vm.prank(p1);
        game.claim();
        assertEq(p1.balance, 11 ether);
        assertEq(p1, game.winner());
    }

    // p2 reveals but p1 does not
    function test_ClaimSuccessOnCommitPhase() public {
        test_ParticipateSuccess();
        (bytes32 _commit1, ) = setCommit(
            RockScissorsPaperLib.Hand.Rock,
            RockScissorsPaperLib.Hand.Paper
        );

        // commit p1 with rock
        vm.prank(p1);
        game.commit(_commit1);

        vm.warp(block.timestamp + expiration * 2);
        vm.prank(p1);
        game.claim();
        assertEq(p1.balance, 11 ether);
        assertEq(p1, game.winner());
    }

    function test_TiedGame() public {
        test_ParticipateSuccess();
        (bytes32 _commit1, bytes32 _commit2) = setCommit(
            RockScissorsPaperLib.Hand.Rock,
            RockScissorsPaperLib.Hand.Rock
        );

        vm.prank(p1);
        game.commit(_commit1);
        vm.prank(p2);
        game.commit(_commit2);

        vm.prank(p1);
        game.reveal(RockScissorsPaperLib.Hand.Rock, salt1);
        vm.prank(p2);
        game.reveal(RockScissorsPaperLib.Hand.Rock, salt2);

        assertEq(game.winner(), address(0));
        assertEq(uint(game.phase()), uint(Game.Phase.Commit));
    }
}

