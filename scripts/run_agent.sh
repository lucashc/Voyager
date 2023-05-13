#!/bin/bash

if [[ $# != 2 ]] ; then
    echo 'Please provide the number of agents to run: ./run_agent.sh <number_of_agents> <number_of_hitmen>'
    exit -1
fi

AGENTS=$(seq $1 | awk '{print "/mnt/main.lua"}')
HITMEN=$(seq $2 | awk '{print "/mnt/hitman.lua"}')

echo "Running Image with $1 agents and $2 hitmen"
podman run -v ./results:/files:z -v ./:/mnt:z --rm --name agent -it tarasyarema/sqlillo $AGENTS $HITMEN

echo "Rename results"
mv results/traces.json "results/$(date -Iseconds)_trace.json"