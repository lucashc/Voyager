#!/bin/bash

echo "Running Image"
podman run -v ./results:/files:z -v ./main.lua:/mnt/main.lua --rm --name agent -it tarasyarema/sqlillo /mnt/main.lua /mnt/main.lua /mnt/main.lua /mnt/main.lua

echo "Rename results"
mv results/traces.json "results/$(date -Iseconds)_trace.json"