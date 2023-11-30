#!/bin/sh

source .env

anvil &
PID=$!

sleep 1

forge script script/GameFactory.s.sol:GameFactoryScript --fork-url http://localhost:8545 --broadcast

wait $PID
