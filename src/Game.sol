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
    bool terminated;

    event Winner(address indexed winner, uint prize);
    event Terminate(bool term);

    modifier checkNotTerminated() {
        require (terminated != true, "The game is terminated");
        _;
    }

    constructor(
        address _creator,
        uint16 _expiration,
        uint _betSize
    ) {
        betSize = _betSize;
        expiration = _expiration;
        player1.player = payable(_creator);
    }

    function _win(address payable _player) private {
        uint amount = address(this).balance;
        _player.sendValue(amount);
        emit Winner(_player, amount);
    }

    // TODO: library
    function _checkCommit(bytes32 _commit, RockScissorsPaperLib.Hand _hand, bytes32 _salt)
        private
        pure
        returns (bool _same)
    {
        _same = _commit == keccak256(abi.encodePacked(_hand, _salt));
    }

    /// @dev Hard -> two of one has leaved game.
    function _resetHard() internal {
        if (_msgSender() == player2.player) {
            player1.player = player2.player;
        }
        delete player2;
        delete player1.commit;
        delete player1.hand;
        delete player1.betDone;
        delete phaseExpiration;
        _setPhase(Phase.Participate);
        emit UpdatePlayer(player1.player);
        emit UpdatePlayer(player2.player);
    }

    /// @dev Medium -> game epoch reached to end.
    function _resetMedium() internal {
        delete player2.commit;
        delete player2.hand;
        delete player2.betDone;
        delete player1.commit;
        delete player1.hand;
        delete player1.betDone;
        _setPhase(Phase.Bet);
        _setPhaseExpiration();
        emit UpdatePlayer(player1.player);
        emit UpdatePlayer(player2.player);
    }

    /// @dev soft -> both are tied on reveal.
    function _resetSoft() internal {
        delete player2.commit;
        delete player2.hand;
        delete player1.commit;
        delete player1.hand;
        _setPhase(Phase.Commit);
        _setPhaseExpiration();
        emit UpdatePlayer(player1.player);
        emit UpdatePlayer(player2.player);
    }

    /// @dev player1 is already participated when this contract is being deployed.
    function participate()
        external
        checkNotTerminated
    {
        require(phase == Phase.Participate, "Failed to join game, game is already in process");

        player2.player = payable(_msgSender());
        emit UpdatePlayer(player2.player);

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
        require(msg.value == betSize, "Failed to bet, insufficient balance to bet");
        (Player storage self, Player storage opponent) = _getPlayer(_msgSender());

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
        emit UpdatePlayer(self.player);

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
        emit UpdatePlayer(self.player);

        if (opponent.hand != RockScissorsPaperLib.Hand.Empty) {
            (bool tied, bool won) = self.hand.checkWin(opponent.hand);
            if (tied) {
                _resetSoft();
            } else {
                won == true
                    ? _win(self.player)
                    : _win(opponent.player);
                _resetMedium();
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

        if (phase == Phase.Bet) {
            require(opponent.betDone == false, "Failed to claim, opponent committed successfully");
        } else {
            else if (phase == Phase.Commit) {
                require(opponent.commit == bytes32(0), "Failed to claim, opponent committed successfully");
            } else {
                require(opponent.hand == RockScissorsPaperLib.Hand.Empty, "Failed to claim, opponent revealed successfully");
            }
            _win(self.player);
        }
        _resetHard();
    }

    function terminate()
        external
        onlyGameCreator
    {
        require(phase == Phase.Participate, "Failed to terminate game, the game is on going");
        require(terminated == false, "Failed to terminate game, already terminated");
        terminated = true;
        emit Terminate(terminated);
    }
}
