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
    string public title;
    bool terminated;

    event Winner(address indexed winner, address indexed challenger, uint prize);
    event Terminate(bool term);

    // constructor(uint16 _expiration, address _gameCreator) payable {
    //     require(msg.value > 0);
    //     expiration = _expiration;
    //     betSize = msg.value;
    //     player1.player = payable(_gameCreator);
    // }

    modifier checkNotTerminated() {
        require (terminated != true, "The game is terminated");
        _;
    }

    constructor(
        address _creator,
        uint16 _expiration,
        uint _betSize,
        string _title
    ) {
        betSize = _betSize;
        expiration = _expiration;
        title = _title;
        player1.player = _creator;
    }

    function _win(address payable _player) private {
        _player.sendValue(betSize * 2);
        emit Winner(_player, betSize * 2);
    }

    // TODO: library
    function _checkCommit(bytes32 _commit, RockScissorsPaperLib.Hand _hand, bytes32 _salt)
        private
        pure
        returns (bool _same)
    {
        _same = _commit == keccak256(abi.encodePacked(_hand, _salt));
    }

    function participate()
        external
        checkNotTerminated
    {
        require(phase == Phase.Participate, "Failed to join game, game is already in process");

        player2.player = payable(_msgSender());
        emit UpdatePlayer(player2.player, player2.commit, player2.hand);

        _setPhase(Phase.Bet);
        _initPhaseClock();
        _setPhaseExpiration();
    }

    /// @dev onlyParticipants check must be prior to checkPhaseExpired
    function bet()
        external
        payable
        checkNotTerminated
        onlyParticipants
        checkPhaseExpired
    {
        require(phase == Phase.Bet, "Failed to bet, game is not int betting phase");
        require(msg.value == betSize(), "Failed to bet, insufficient balance to bet");
        (Player storage self, Player storage opponent) = _getPlayer(_msgSender());

        // _checkPhaseExpired(_msgSender());
        self.betDone = true;

        if (opponent.betDone == true) {
            _setPhase(Phase.Commit);
            _setPhaseExpiration();
        }
    }

    function commit(bytes32 _commit)
        external
        checkNotTerminated
        onlyParticipants
        checkPhaseExpired
    {
        require(phase == Phase.Commit, "Failed to commit, game phase is reveal or participate");
        (Player storage self, Player storage opponent) = _getPlayer(_msgSender());
        require(self.commit == bytes32(0), "msg.sender already committed");

        self.commit = _commit;
        emit UpdatePlayer(self.player, self.commit, self.hand);

        // check opponent submitted commit
        if (opponent.commit != bytes32(0)) {
            _setPhase(Phase.Reveal);
            _setPhaseExpiration();
        }
    }

    function reveal(RockScissorsPaperLib.Hand _hand, bytes32 _salt)
        external
        onlyParticipants
        checkNotTerminated
        checkPhaseExpired
        nonReentrant
    {
        require(phase == Phase.Reveal, "Failed to reveal, game phase is commit or participate");
        (Player storage self, Player storage opponent) = _getPlayer(_msgSender());
        require(self.hand == RockScissorsPaperLib.Hand.Empty, "Failed to reveal, sender already revealed");
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

    function claimOpponentVanished()
        external
        checkNotTerminated
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

    function terminate()
        public
        onlyGameCreator
    {
        require(phase == Phase.Participate, "Failed to terminate game, the game is on going");
        terminated = true;
        emit Terminate(terminated);
    }
}
