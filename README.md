# Rock Scissors Paper On Smart Contract
This repository is smart contract development of rock-scissors-paper powered by blockchain. \
Players can create a game which alikes room with size of betting. \
If opponent participate in the game, they start rock-scissors-paper with 3 steps - bet, commit, reveal.

## Features
### CreateGame
GameFactory.sol contract keep tracks a number of games owned by the creator. \
The number (0 to number of games) represents game number because when creating game using `new` keward, it adds the number as salt. \
So when one wants to find address of game played, simply use GetGameAddress function that calculate address of Game contract.

### Participate
If one wants to join game, he/she manually call participate function to join. \
When participation succeed, the phase shifts to `Bet` phase and game clock (expiration clock) starts to tick.

### Bet
In `Bet` phase, both should call bet function giving ether equavalant to the bet size state variable initiallized by constructor.

### Commit
In `Commit` phase, both should call commit function with their commit which is keccak hashed bytes32 rock || scissors || paper and random number named salt.

### Reveal
In `Reveal` phase, at lease one should call reveal function with their rock || scissors || paper and salt used. \
In this phase, if one who does not reveal, opponent takes winner.
Winner takes all the money in the pot and if game is tied, the phase becomes `Commit` and play again.

### ClaimOpponentVanished
The game can not be done ideally - both of one or both may not take required actions on each step except `Participate` phase. \
So if opponent does not take action, the player can claim opponent has been vanished. \
It will kick out the player or makes the player winner resetting the game.
