#!/bin/bash
if [ "$1" == "beforefetch" ]; then
    tree data -s -f > beforefetch.txt
fi

if [ "$1" == "fetch" ]; then
    ./fetch.sh
fi

if [ "$1" == "afterfetch" ]; then
    tree data -s -f > afterfetch.txt
fi

generateDb() {
    # Generate Funds Dataset
    pypy3 generate.py
    zstd -5 -T0 funds.db

    # Generate Latest Dataset
    pypy3 generate-latest.py
    zstd -5 -T0 latest.db
}

generateRelease() {
    # Check for version
    gh release view latest > release.txt

    if [ $(wc -c < release.txt) -gt 0 ]; then
        # If version exists, regenerate version with new data
        gh release delete "latest" -y --cleanup-tag
        gh release create "latest" --notes "Historical Mutual Fund Data as per $vDate. Please see README for index creation, usage, and schema." *.zst
    else
        # Else generate version with new data
        gh release create "latest" --notes "Historical Mutual Fund Data as per $vDate. Please see README for index creation, usage, and schema." *.zst
    fi

    rm release.txt
}

checkAndGenerateRelease() {
    # Check for version
    gh release view latest > release.txt

    if [ $(wc -c < release.txt) -eq 0 ]; then
        generateDb

        # Else generate version with new data
        gh release create "latest" --notes "Historical Mutual Fund Data as per $vDate. Please see README for index creation, usage, and schema." *.zst
    fi

    rm release.txt
}

if [ "$1" == "fundsdataset" ]; then
    git config user.email "github-actions[bot]@users.noreply.github.com"
    git config user.name "github-actions[bot]"

    diff beforefetch.txt afterfetch.txt > diff.txt

    if [ $(wc -c < diff.txt) -gt 0 ]; then
        generateDb
        generateRelease
    else
        checkAndGenerateRelease
    fi

    rm diff.txt beforefetch.txt afterfetch.txt
fi