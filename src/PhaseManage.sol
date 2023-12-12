// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract PhaseManage {
    enum Phase {
        Participate,
        Commit,
        Reveal
    }

    Phase public phase;

    uint16 expiration;
    uint32 phaseExpiration;

    event PhaseChanged(Phase phase);

    function _setPhase(Phase _phase) internal {
        phase = _phase;
        emit PhaseChanged(phase);
    }

    function _setPhaseExpiration() internal {
        phaseExpiration += uint32(expiration);
    }
}