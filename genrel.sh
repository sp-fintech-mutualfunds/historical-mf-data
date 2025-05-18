#!/bin/bash
#Release should only be generate if there is a difference in data.
if [ "$1" == "beforefetch" ]; then
    tree data -s -f > beforefetch.txt
fi

if [ "$1" == "fetch" ]; then
    ./fetch.sh
fi

if [ "$1" == "afterfetch" ]; then
    tree data -s -f > afterfetch.txt
fi

if [ "$1" == "fundsdataset" ]; then
    diff beforefetch.txt afterfetch.txt > diff.txt

    if [ $(wc -c < diff.txt) -gt 0 ]; then
        git config user.email "github-actions[bot]@users.noreply.github.com"
        git config user.name "github-actions[bot]"

        # Generate Funds Dataset
        pypy3 generate.py
        zstd -5 -T0 funds.db

        # Generate Latest Dataset
        pypy3 generate-latest.py
        zstd -5 -T0 latest.db

        # Check for version
        today=$(date -I)
        vDate=$(date '+%Y%m%d' -d "$today")
        gh release view v0.0.$vDate > release.txt

        if [ $(wc -c < release.txt) -gt 0 ]; then
            # If version exists, regenerate version with new data
            gh release delete "v0.0.$vDate" -y --cleanup-tag
            gh release create "v0.0.$vDate" --notes "Historical Mutual Fund Data as per $vDate. Please see README for index creation, usage, and schema." *.zst
        else
            # Else generate version with new data
            gh release create "v0.0.$vDate" --notes "Historical Mutual Fund Data as per $vDate. Please see README for index creation, usage, and schema." *.zst
        fi

        rm release.txt
    fi

    rm diff.txt beforefetch.txt afterfetch.txt
fi