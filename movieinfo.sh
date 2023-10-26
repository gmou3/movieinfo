#!/bin/bash

# Read Movie and Search
read -p "Search: " movie
movie=$(echo $movie | sed -r 's/ /%20/g')
content=$(wget https://www.rottentomatoes.com/search?search=$movie -qO -)
readarray movies -t <<< $(echo $content | grep -oP '(?<=<search-page-media-row).*?(?=</search-page-media-row>)')
readarray titleList -t <<< $(echo ${movies[@]} | grep -oP '(?<=slot="title"> ).*?(?= </a>)' | sed "s/&#39;/'/g" | sed 's/&amp;/\&/g')
readarray yearList -t <<< $(echo ${movies[@]} | grep -oP '(?<=releaseyear=").*?(?=")')
readarray linkList -t <<< $(echo ${movies[@]} | grep -oP '(?<= </a> <a href=").*?(?=" class="unset" data-qa="info-name" slot="title">)')

# Movie Choice Dialog
if [ ${#titleList[$i]} != 1 ]; then
    echo 'Choose movie:'
else
    echo 'No results'
    exit
fi
for i in $(seq 0 7);
do
    if [ ${#titleList[$i]} != 0 ]; then
        echo '  '$i. ${titleList[$i]} \(${yearList[$i]:=-}\) | sed 's/ )/)/'
    fi
done
read -p "Choice: " choice

# Retrieve Chosen Movie Info
content=$(wget ${linkList[choice]} -qO -)
thumbnail=$(echo $content | grep -oP '(?<=<meta property="og:image" content=").*?(?=">)')
wget -q $thumbnail -O /tmp/thumbnail.jpg
description=$(echo $content | grep -oP '(?<=description":").*?(?=",")' | head -1)
language=$(echo $content | grep -oP '(?<=Original Language:</b> <span data-qa="movie-info-item-value">).*?(?=</span>)')
director=$(echo $content | grep -oP '(?<="movie-info-director">).*?(?=</a>)')
runtime=$(echo $content | grep -oP '(?<=mM"> ).*?(?= </time>)')
genre=$(echo $content | grep -oP '(?<="titleGenre":").*?(?=")' | head -1)
tmp=$(echo $content | grep -oP '(?<=<score-board-deprecated).*?(?=</score-board-deprecated>)')
tomatoscore=$(echo $tmp | grep -oP '(?<=tomatometerscore=").*?(?=")')
audiencescore=$(echo $tmp | grep -oP '(?<=audiencescore=").*?(?=")')

# Text Formatting
BOLD='\e[1m'
RED='\e[1;31m'
NRM='\e[0m' # Normal

# Print Chosen Movie Info
script -q -c 'asciiart -c -w 25 /tmp/thumbnail.jpg' -O /dev/null >> /tmp/thumbnail.txt
echo -e ${BOLD}${titleList[$choice]} \(${yearList[$choice]:=-}\)${NRM} | sed 's/ )/)/' >> /tmp/movieinfo.txt
if [ "$description" = "Rotten Tomatoes every day." ]; then
    echo '-' >> /tmp/movieinfo.txt
else
    echo ${description:=No description available} >> /tmp/movieinfo.txt
fi
echo ''
echo -e ${BOLD}Visit${NRM}: ${linkList[choice]}
echo ''
echo '' >> /tmp/movieinfo.txt
echo -e ${BOLD}Language${NRM}: ${language:=-} >> /tmp/movieinfo.txt
echo -e ${BOLD}Director${NRM}: ${director:=-} >> /tmp/movieinfo.txt
echo -e ${BOLD}Runtime${NRM}: ${runtime:=-} >> /tmp/movieinfo.txt
echo -e ${BOLD}Genre${NRM}: ${genre:=-} >> /tmp/movieinfo.txt
echo '' >> /tmp/movieinfo.txt
echo -e ${RED}Tomatometer${NRM}: ${tomatoscore:=-} >> /tmp/movieinfo.txt
echo -e ${BOLD}Audience Score${NRM}: ${audiencescore:=-} >> /tmp/movieinfo.txt
fold -s -w55 /tmp/movieinfo.txt > /tmp/movieinfostd.txt
if [ "$(cat /tmp/thumbnail.txt | grep asciiart)" ]; then # In case of asciiart error no image
    cp /tmp/movieinfostd.txt /tmp/output.txt
else
    paste /tmp/thumbnail.txt /tmp/movieinfostd.txt | sed 's/\t/\t\t\t\t/' >> /tmp/output.txt
fi
cat /tmp/output.txt

# Clear Cache
rm /tmp/thumbnail.jpg /tmp/thumbnail.txt /tmp/movieinfo.txt /tmp/movieinfostd.txt /tmp/output.txt