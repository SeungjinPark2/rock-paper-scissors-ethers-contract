// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract PhaseManage {
    enum Phase {
        Participate,
        Bet,
        Commit,
        Reveal
    }

    Phase public phase;

    uint16 expiration;
    uint32 phaseExpiration;

    event PhaseChanged(Phase phase);
    // TODO: need to fix
    /*
    * requirements:
    * Bet : both expired -> terminate game
    *       a person expired -> challenger -> reset game (another challenger may participate in)
    *                        -> game creator -> give back challenger's money and terminate game
    * Commit : both expired -> give back both's money -> terminate game
    *          a person expired -> challenger -> give prize to game creator -> reset game
    *                           -> game creator -> give prize to challenger -> terminate game
    * Reveal : both expired -> give back both's money -> terminate game
    *          a persone expired -> challenger -> give prize to game creator -> reset game
    *                            -> game creator -> give prize to challenger -> terminate game
    */
    // function _checkPhaseExpired(address _player) private {
    //     if (block.timestamp > phaseExpiration) {
    //         (,Player storage opponent) = _getPlayer(_player);
    //         _win(opponent.player);
    //     }
    // }

    modifier checkPhaseExpired() internal {
        require(block.timestamp > phaseExpiration, "Phase is already expired");
    }

    function _setPhase(Phase _phase) internal {
        phase = _phase;
        emit PhaseChanged(phase);
    }

    function _setPhaseExpiration() internal {
        phaseExpiration += uint32(expiration);
    }

    function _initPhaseClock() internal {
        phaseExpiration = block.timestamp;
    }
}
