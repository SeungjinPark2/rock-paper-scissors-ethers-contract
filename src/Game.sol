// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "src/libraries/RockScissorsPaperLib.sol";
import "src/interfaces/IGame.sol";

contract Game is IGame {
    using RockScissorsPaperLib for RockScissorsPaperLib.Hand;

    struct Player {
        address player;
        bytes32 commit;
        RockScissorsPaperLib.Hand hand;
    }
    Player public player1;
    Player public player2;

    address public winner;
    uint public betSize;

    uint32 phaseExpiration;
    uint16 expiration;
    bool public gameClosed;

    enum Phase {
        Participate,
        Commit,
        Reveal
    }

    Phase public phase;

    modifier whenNotClosed() {
        require(gameClosed == false);
        _;
    }

    modifier onlyParticipants() {
        require(player1.player == msg.sender || player2.player == msg.sender);
        _;
    }

    constructor(uint16 _expiration) {
        expiration = _expiration;
    }

    function _setPhase(Phase _phase) private {
        phase = _phase;
    }

    // _opposite true to opponent, false to self
    function _getPlayer(address _player)
        private
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

    function _win(address _player) private {
        winner = _player;
        (bool success, ) = _player.call{value: address(this).balance}("");
        require(success);

        gameClosed = true;
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

    function _setPhaseExpiration() private {
        phaseExpiration += uint32(expiration);
    }

    function participate()
        external
        payable
        whenNotClosed
    {
        require(phase == Phase.Participate);
        if (player1.player == address(0)) {
            require(msg.value > 0);

            betSize = msg.value;
            player1.player = msg.sender;
        } else {
            require(msg.value == betSize);

            player2.player = msg.sender;
            _setPhase(Phase.Commit);
            _setPhaseExpiration();
        }
    }

    function commit(bytes32 _commit)
        external
        whenNotClosed
        onlyParticipants
    {
        require(phase == Phase.Commit);
        (Player storage self, Player storage opponent) = _getPlayer(msg.sender);
        require(self.commit == bytes32(0));

        _checkPhaseExpired(msg.sender);
        self.commit = _commit;

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
        whenNotClosed
        onlyParticipants
    {
        require(phase != Phase.Participate);
        require(block.timestamp > phaseExpiration);

        (, Player storage opponent) = _getPlayer(msg.sender);

        phase == Phase.Commit
            ? require(opponent.commit == bytes32(0))
            : require(opponent.hand == RockScissorsPaperLib.Hand.Empty);

        _win(msg.sender);
    }

    function reveal(RockScissorsPaperLib.Hand _hand, bytes32 _salt)
        external
        whenNotClosed
        onlyParticipants
    {
        require(phase == Phase.Reveal);
        (Player storage self, Player storage opponent) = _getPlayer(msg.sender);
        require(self.hand == RockScissorsPaperLib.Hand.Empty);

        _checkPhaseExpired(msg.sender);
        require(_checkCommit(self.commit, _hand, _salt));
        self.hand = _hand;

        if (opponent.hand != RockScissorsPaperLib.Hand.Empty) {
            (bool tied, bool won) = self.hand.checkWin(opponent.hand);
            if (tied) {
                delete self.commit;
                delete self.hand;
                delete opponent.commit;
                delete opponent.hand;
                phase = Phase.Commit;
            } else {
                won == true
                    ? _win(self.player)
                    : _win(opponent.player);
            }
        }
    }

    function leave()
        external
        whenNotClosed
        onlyParticipants
    {
        if (phase == Phase.Participate) {
            (bool success, ) = player1.player.call{value: betSize}("");
            require(success);

            gameClosed = true;
        } else {
            (, Player storage opponent) = _getPlayer(msg.sender);
            _win(opponent.player);
        }
    }
}

