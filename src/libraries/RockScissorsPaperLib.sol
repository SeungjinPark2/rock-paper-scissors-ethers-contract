// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

library RockScissorsPaperLib {
    enum Hand {
        Empty,
        Rock,
        Scissors,
        Paper
    }

    // returns win to true when hand1 wins hand2
    function checkWin(Hand hand1, Hand hand2) internal pure returns (bool tied, bool won) {
        require (hand1 != Hand.Empty && hand2 != Hand.Empty);
        if (hand1 == hand2) {
            tied = true;
        } else {
            if ((hand1 == Hand.Rock && hand2 == Hand.Scissors)
                || (hand1 == Hand.Scissors && hand2 == Hand.Paper)
                || (hand1 == Hand.Paper && hand2 == Hand.Rock)
               ) {
                won = true;
            }
        }
    }
}
