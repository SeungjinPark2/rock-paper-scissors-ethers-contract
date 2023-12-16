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
    uint public phaseExpiration;

    event PhaseChanged(Phase phase);

    modifier checkPhaseExpired() {
        require(block.timestamp < phaseExpiration, "Phase is already expired");
        _;
    }

    function _setPhase(Phase _phase) internal {
        phase = _phase;
        emit PhaseChanged(phase);
    }

    function _setPhaseExpiration() internal {
        phaseExpiration += uint(expiration);
    }

    function _initPhaseClock() internal {
        phaseExpiration = block.timestamp;
    }
}
