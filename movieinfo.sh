#!/bin/bash

# Text formatting
BOLD='\e[1m'
RED='\e[1;31m'
BLUE='\e[1;34m'
NRM='\e[0m' # Normal

# Read movie and search
printf ${BOLD}Search${NRM}:' '
read movie
movie=$(echo $movie | sed -r 's/ /%20/g')
content=$(wget https://www.rottentomatoes.com/search?search=$movie -qO -)
readarray movies -t <<< $(echo $content | grep -oP '(?<=<search-page-media-row).*?(?=</search-page-media-row>)')
readarray titleList -t <<< $(echo ${movies[@]} | grep -oP '(?<=slot="title"> ).*?(?= </a>)' | sed "s/&#39;/'/g" | sed 's/&amp;/\&/g')
readarray yearList -t <<< $(echo ${movies[@]} | grep -oP '(?<=releaseyear=").*?(?=")')
readarray linkList -t <<< $(echo ${movies[@]} | grep -oP '(?<= </a> <a href=").*?(?=" class="unset" data-qa="info-name" slot="title">)')

# Movie choice dialog
if [ ${#titleList[$i]} != 1 ]; then
    printf "${BOLD}Choose movie${NRM}:\n"
else
    printf "${BOLD}No results${NRM}\n"
    exit
fi
for i in $(seq 0 7);
do
    if [ ${#titleList[$i]} != 0 ]; then
        printf "\t${BLUE}$i${NRM}. ${titleList[$i]} (${yearList[$i]:=-})" | tr -d '\n'
        printf '\n'
    fi
done
printf "${BOLD}Choice (${BLUE}0${NRM}${BOLD})${NRM}: "
read choice

# Retrieve chosen movie info
content=$(wget ${linkList[$choice]} -qO -)

img=$(echo $content | grep -oP '(?<=<meta property="og:image" content=").*?(?=">)')
wget -q $img -O /tmp/img.jpg

description=$(echo $content | grep -oP '(?<=description":").*?(?=",")' | head -1)
language=$(echo $content | grep -oP '(?<=Original Language:</b> <span data-qa="movie-info-item-value">).*?(?=</span>)')
director=$(echo $content | grep -oP '(?<="movie-info-director">).*?(?=</a>)')
runtime=$(echo $content | grep -oP '(?<=mM"> ).*?(?= </time>)')
genre=$(echo $content | grep -oP '(?<="titleGenre":").*?(?=")' | head -1)
tmp=$(echo $content | grep -oP '(?<=<score-board-deprecated).*?(?=</score-board-deprecated>)')
tomatoscore=$(echo $tmp | grep -oP '(?<=tomatometerscore=").*?(?=")')
audiencescore=$(echo $tmp | grep -oP '(?<=audiencescore=").*?(?=")')

# Print chosen movie info
termwidth=$(tput cols) # terminal width
asciiwidth=$((27*$termwidth/100))
txtwidth=$((6*$termwidth/10))
script -q -c "asciiart -c -w $asciiwidth /tmp/img.jpg" -O /dev/null >> /tmp/imgdos
tr -d '\r' < /tmp/imgdos > /tmp/img # dos to unix

printf "${BOLD}${titleList[$choice]} (${yearList[$choice]:=-})${NRM}" | tr -d '\n' >> /tmp/mvinfo
if [ "$description" = "Rotten Tomatoes every day." ]; then
    printf "\n-" >> /tmp/mvinfo
else
    printf "\n${description:=No description available}\n" >> /tmp/mvinfo
fi
printf "\n${BOLD}Visit${NRM}: ${linkList[choice]}\n"
printf "\n${BOLD}Language${NRM}: ${language:=-}\n" >> /tmp/mvinfo
printf "${BOLD}Director${NRM}: ${director:=-}\n" >> /tmp/mvinfo
printf "${BOLD}Runtime${NRM}: ${runtime:=-}\n" >> /tmp/mvinfo
printf "${BOLD}Genre${NRM}: ${genre:=-}\n\n" >> /tmp/mvinfo
printf "${RED}Tomatometer${NRM}: ${tomatoscore:=-}\n" >> /tmp/mvinfo
printf "${BOLD}Audience Score${NRM}: ${audiencescore:=-}\n" >> /tmp/mvinfo
fold -s -w $txtwidth /tmp/mvinfo > /tmp/mvinfostd
if [ "$(cat /tmp/img | grep asciiart)" ]; then # In case of asciiart error no image
    cp /tmp/mvinfostd /tmp/output
else
    paste /tmp/img /tmp/mvinfostd >> /tmp/output
fi
cat /tmp/output

# Clear temporary files
rm /tmp/img.jpg /tmp/img /tmp/imgdos /tmp/mvinfo /tmp/mvinfostd /tmp/output