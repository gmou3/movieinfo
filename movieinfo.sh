#!/bin/bash

# Read Movie and Search
read -p "Search: " movie
movie=$(echo $movie | sed -r 's/ /%20/')
content=$(wget https://www.rottentomatoes.com/search?search=$movie -qO -)
readarray movies -t <<< $(echo $content | grep -oP '(?<=<search-page-media-row).*?(?=</search-page-media-row>)')
readarray titleList -t <<< $(echo ${movies[@]} | grep -oP '(?<=slot="title">).*?(?= </a>)' | sed "s/&#39;/'/")
readarray yearList -t <<< $(echo ${movies[@]} | grep -oP '(?<=releaseyear=").*?(?=")')
readarray linkList -t <<< $(echo ${movies[@]} | grep -oP '(?<= </a> <a href=").*?(?=" class="unset" data-qa="info-name" slot="title">)')

# Movie Choice Dialog
echo "Choose movie:"
for i in $(seq 0 5);
do
    if [ "${titleList[$i]}" ]; then
        echo "  "$i. ${titleList[$i]} \(${yearList[$i]:=-}\) | sed 's/ )/)/'
    fi
done
read -p "Choice: " choice

# Retrieve Chosen Movie Info
content=$(wget ${linkList[choice]} -qO -)
thumbnail=$(echo $content | grep -oP '(?<=<meta property="og:image" content=").*?(?=">)')
wget -q $thumbnail -O /tmp/thumbnail.jpg
description=$(echo $content | grep -oP '(?<=description":").*?(?=",")' | head -1)
genre=$(echo $content | grep -oP '(?<="titleGenre":").*?(?=")' | head -1)
tmp=$(echo $content | grep -oP '(?<=<score-board-deprecated).*?(?=</score-board-deprecated>)')
tomatoscore=$(echo $tmp | grep -oP '(?<=tomatometerscore=").*?(?=")')
audiencescore=$(echo $tmp | grep -oP '(?<=audiencescore=").*?(?=")')

# Text Formatting
BOLD='\e[1m'
RED='\e[1;31m'
NORM='\e[0m' # Normal

# Print Chosen Movie Info

asciiart -c -w 20 /tmp/thumbnail.jpg
echo -e ${BOLD}${titleList[$choice]} \(${yearList[$choice]:=-}\)${NORM} | sed 's/ )/)/'
echo $description
echo -e ${BOLD}Genre${NORM}: ${genre:=-}
echo -e ${RED}tomatoscore${NORM}: ${tomatoscore:=-}, ${BOLD}audiencescore${NORM}: ${audiencescore:=-}

# Clear Cache
rm /tmp/thumbnail.jpg