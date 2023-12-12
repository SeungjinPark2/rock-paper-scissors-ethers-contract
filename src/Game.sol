// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "src/libraries/RockScissorsPaperLib.sol";
import "src/PlayerManage.sol";
import "src/PhaseManage.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract Game is ReentrancyGuard, PlayerManage, PhaseManage {
    using RockScissorsPaperLib for RockScissorsPaperLib.Hand;
    using Address for address payable;

    uint public betSize;
    event Winner(address winner, uint prize);

    constructor(uint16 _expiration, address _gameCreator) payable {
        require(msg.value > 0);
        expiration = _expiration;
        betSize = msg.value;
        player1.player = payable(_gameCreator);
    }

    function _win(address payable _player) private {
        _player.sendValue(betSize * 2);
        emit Winner(_player, betSize * 2);
    }

    // if phase was expiered, then
    function _checkPhaseExpired(address _player) private {
        if (block.timestamp > phaseExpiration) {
            (,Player storage opponent) = _getPlayer(_player);
            _win(opponent.player);
        }
    }

    function _checkCommit(bytes32 _commit, RockScissorsPaperLib.Hand _hand, bytes32 _salt)
        private
        pure
        returns (bool _same)
    {
        _same = _commit == keccak256(abi.encodePacked(_hand, _salt));
    }

    function participate()
        external
        payable
    {
        require(phase == Phase.Participate, "Failed to join game, game is already in process");
        require(msg.value == betSize, "Failed to join game, different bet");

        player2.player = payable(_msgSender());
        emit UpdatePlayer(player2.player, player2.commit, player2.hand);
        _setPhase(Phase.Commit);
        _setPhaseExpiration();
    }

    function commit(bytes32 _commit)
        external
        onlyParticipants
    {
        require(phase == Phase.Commit, "Failed to commit, game phase is reveal or participate");
        (Player storage self, Player storage opponent) = _getPlayer(_msgSender());
        require(self.commit == bytes32(0), "msg.sender already committed");

        _checkPhaseExpired(_msgSender());
        self.commit = _commit;
        emit UpdatePlayer(self.player, self.commit, self.hand);

        // check opponent submitted commit
        if (opponent.commit != bytes32(0)) {
            _setPhase(Phase.Reveal);
            _setPhaseExpiration();
        }
    }

    // If opponent does not take any steps within commit or reveal phase after phase expiered,
    // participant can claim his/her win.
    function claim()
        external
        onlyParticipants
        nonReentrant
    {
        require(phase != Phase.Participate, "Failed to claim, game is not in process");
        require(block.timestamp > phaseExpiration, "Failed to claim, the game phase is not expired");

        (Player storage self, Player storage opponent) = _getPlayer(_msgSender());

        phase == Phase.Commit
            ? require(opponent.commit == bytes32(0), "Failed to claim, opponent committed successfully")
            : require(opponent.hand == RockScissorsPaperLib.Hand.Empty, "Failed to claim, opponent revealed successfully");

        _win(self.player);
    }

    function reveal(RockScissorsPaperLib.Hand _hand, bytes32 _salt)
        external
        onlyParticipants
        nonReentrant
    {
        require(phase == Phase.Reveal, "Failed to reveal, game phase is commit or participate");
        (Player storage self, Player storage opponent) = _getPlayer(_msgSender());
        require(self.hand == RockScissorsPaperLib.Hand.Empty, "Failed to reveal, sender already revealed");

        _checkPhaseExpired(_msgSender());
        require(_checkCommit(self.commit, _hand, _salt), "Failed to reveal, msg.sender's reveal is wrong");
        self.hand = _hand;
        emit UpdatePlayer(self.player, self.commit, self.hand);

        if (opponent.hand != RockScissorsPaperLib.Hand.Empty) {
            (bool tied, bool won) = self.hand.checkWin(opponent.hand);
            if (tied) {
                delete self.commit;
                delete self.hand;
                delete opponent.commit;
                delete opponent.hand;
                emit UpdatePlayer(self.player, self.commit, self.hand);
                emit UpdatePlayer(opponent.player, opponent.commit, opponent.hand);
                _setPhase(Phase.Commit);
            } else {
                won == true
                    ? _win(self.player)
                    : _win(opponent.player);
            }
        }
    }

    function leave()
        external
        onlyParticipants
        nonReentrant
    {
        if (phase == Phase.Participate) {
            player1.player.sendValue(betSize);
        } else {
            (, Player storage opponent) = _getPlayer(_msgSender());
            _win(opponent.player);
        }
    }
}
