// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "src/libraries/RockScissorsPaperLib.sol";
import "@openzeppelin/contracts/utils/Context.sol";

contract PlayerManage is Context {
    struct Player {
        address payable player;
        bool betDone;
        bytes32 commit;
        RockScissorsPaperLib.Hand hand;
    }

    Player public player1;
    Player public player2;

    modifier onlyParticipants() {
        require(
            player1.player == _msgSender() || player2.player == _msgSender(),
            "msg.sender is not a participant of this game"
        );
        _;
    }

    modifier onlyGameCreator() {
        require(
            player1.player == _msgSender(),
            "msg.sender is not a game creator"
        );
        _;
    }

    event UpdatePlayer(address player);

    function _getPlayer(address _player)
        internal
        view
        returns (Player storage self, Player storage opponent)
    {
        self = player1.player == _player
            ? player1
            : player2;
        opponent = self.player == player1.player
            ? player2
            : player1;
    }
}
