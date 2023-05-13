#!/bin/bash

echo "Running Image"
podman run -v ./results:/files:z -v ./:/mnt:z --rm --name agent -it tarasyarema/sqlillo /mnt/main.lua /mnt/main.lua /mnt/main.lua /mnt/main.lua /mnt/hitman.lua /mnt/hitman.lua /mnt/hitman.lua

echo "Rename results"
mv results/traces.json "results/$(date -Iseconds)_trace.json"
