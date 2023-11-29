// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "src/libraries/RockScissorsPaperLib.sol";

contract Game {
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
        require(gameClosed == false, "Game is already closed");
        _;
    }

    modifier onlyParticipants() {
        require(
            player1.player == msg.sender || player2.player == msg.sender,
            "msg.sender is not a participant of this game"
        );
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
        require(success, "Failed to send money to winner");

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
        require(phase == Phase.Participate, "Failed to join game, game is already in process");
        if (player1.player == address(0)) {
            require(msg.value > 0, "Failed due to lack of ETH");

            betSize = msg.value;
            player1.player = msg.sender;
        } else {
            require(msg.value == betSize, "Failed due to differentbet");

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
        require(phase == Phase.Commit, "Failed to commit, game phase is reveal or participate");
        (Player storage self, Player storage opponent) = _getPlayer(msg.sender);
        require(self.commit == bytes32(0), "msg.sender already committed");

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
        require(phase != Phase.Participate, "Failed to claim, game is not in process");
        require(block.timestamp > phaseExpiration, "Failed to claim, the game phase is not expired");

        (, Player storage opponent) = _getPlayer(msg.sender);

        phase == Phase.Commit
            ? require(opponent.commit == bytes32(0), "Failed to claim, opponent committed successfully")
            : require(opponent.hand == RockScissorsPaperLib.Hand.Empty, "Failed to claim, opponent revealed successfully");

        _win(msg.sender);
    }

    function reveal(RockScissorsPaperLib.Hand _hand, bytes32 _salt)
        external
        whenNotClosed
        onlyParticipants
    {
        require(phase == Phase.Reveal, "Failed to reveal, game phase is commit or participate");
        (Player storage self, Player storage opponent) = _getPlayer(msg.sender);
        require(self.hand == RockScissorsPaperLib.Hand.Empty, "Failed to reveal, sender already revealed");

        _checkPhaseExpired(msg.sender);
        require(_checkCommit(self.commit, _hand, _salt), "Failed to reveal, msg.sender's reveal is wrong");
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
            require(success, "Failed to send money to winner");

            gameClosed = true;
        } else {
            (, Player storage opponent) = _getPlayer(msg.sender);
            _win(opponent.player);
        }
    }
}

