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
    uint betSize = 1 ether;
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
        game = new Game(p1, expiration, betSize);
        salt1 = keccak256(abi.encodePacked(uint(1)));
        salt2 = keccak256(abi.encodePacked(uint(1)));
    }

    function _setCommit(RockScissorsPaperLib.Hand _hand1, RockScissorsPaperLib.Hand _hand2)
        internal
        view
        returns (bytes32 _commit1, bytes32 _commit2)
    {
        _commit1 = keccak256(abi.encodePacked(_hand1, salt1));
        _commit2 = keccak256(abi.encodePacked(_hand2, salt2));
    }

    function _participate() internal {
        vm.prank(p2);
        game.participate();
    }

    function _betP1() internal {
        vm.prank(p1);
        game.bet{value: betSize}();
    }

    function _betP2() internal {
        vm.prank(p2);
        game.bet{value: betSize}();
    }

    // (bytes32 _commit1, bytes32 _commit2) = _setCommit(RockScissorsPaperLib.Hand.Rock, RockScissorsPaperLib.Hand.Paper);
    function _commitP1(bytes32 _c1) internal {
        vm.prank(p1);
        game.commit(_c1);
    }

    function _commitP2(bytes32 _c2) internal {
        vm.prank(p2);
        game.commit(_c2);
    }

    function _revealP1(RockScissorsPaperLib.Hand _h1, bytes32 _s1) internal {
        vm.prank(p1);
        game.reveal(_h1, _s1);
    }

    function _revealP2(RockScissorsPaperLib.Hand _h2, bytes32 _s2) internal {
        vm.prank(p2);
        game.reveal(_h2, _s2);
    }
}

