// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "src/Game.sol";

contract GameTest is Test {
    Game game;
    address p1;
    address p2;

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
        bytes32 salt1 = keccak256(abi.encodePacked(uint(1)));
        bytes32 salt2 = keccak256(abi.encodePacked(uint(1)));
        bytes32 commit1 = keccak256(abi.encodePacked(uint(RockScissorsPaperLib.Hand.Rock), salt1));
        bytes32 commit2 = keccak256(abi.encodePacked(uint(RockScissorsPaperLib.Hand.Paper), salt2));

        vm.prank(p1);
        game.commit(commit1);
        assertEq(uint(game.phase()), uint(Game.Phase.Commit));
        (, bytes32 _commit1,) = game.player1();
        assertEq(_commit1, commit1);

        vm.prank(p2);
        game.commit(commit2);
        assertEq(uint(game.phase()), uint(Game.Phase.Reveal));
        (, bytes32 _commit2,) = game.player2();
        assertEq(_commit2, commit2);
    }

    function test_RevealSuccess() public {
    }
}
