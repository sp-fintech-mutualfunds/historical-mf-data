#!/bin/bash
#Release should only be generate if there is a difference in data.
tree data -s -f > start.txt
./fetch.sh
tree data -s -f > end.txt
diff start.txt end.txt > diff.txt

if [ $(wc -c < diff.txt) -gt 0 ]; then
    today=$(date -I)
    vDate=$(date '+%Y%m%d' -d "$today")
    gh release view v0.0.$vDate > release.txt

    if [ $(wc -c < release.txt) -gt 0 ]; then
        gh release delete "v0.0.$vDate" -y --cleanup-tag
        gh release create "v0.0.$vDate" --notes "Historical Mutual Fund Data as per $vDate. Please see README for index creation, usage, and schema." *.zst
    else
        gh release create "v0.0.$vDate" --notes "Historical Mutual Fund Data as per $vDate. Please see README for index creation, usage, and schema." *.zst
    fi
fi

rm start.txt end.txt
rm diff.txt release.txt