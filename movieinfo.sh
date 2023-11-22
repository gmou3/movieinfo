#!/bin/bash

# Text formatting
BOLD='\e[1m'
RED='\e[1;31m'
BLUE='\e[1;34m'
YLLW='\e[1;33m'
NRM='\e[0m' # Normal

# Check args
r=false
for arg in "$@"; do
    case $arg in
    -r)
        r=true
        ;;
    *)
        printf "${BOLD}Usage${NRM}: movieinfo [-r]\n\n${BOLD}Flags${NRM}:\n"
        printf "\t-r: realistic image using catimg (instead of default asciiart)\n"
        exit
        ;;
    esac
done

# Warn if asciiart or catimg is unavailable
imgerror=false
if [ "$r" = false ] && [ -z "$(which asciiart)" ]; then
    printf "${YLLW}Warning${NRM}: asciiart is not installed.\n"
    imgerror=true
elif [ "$r" = true ] && [ -z "$(which catimg)" ]; then
    printf "${YLLW}Warning${NRM}: catimg is not installed.\n"
    imgerror=true
fi

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

if [ "$r" = false ]; then # asciiart
    script -q -c "asciiart -c -i -w $asciiwidth /tmp/img.jpg" -O /dev/null >> /tmp/img0
    if [ "$(cat /tmp/img0 | grep asciiart)" ]; then # In case of asciiart error no image
        imgerror=true
    fi
    sed -i 's/\r//g' /tmp/img0 # dos to unix
else # catimg
    catimg -r 2 -w $((2*$asciiwidth)) /tmp/img.jpg &>> /tmp/img0
    if [ "$(cat /tmp/img0 | grep error)" ]; then # In case of catimg error no image
        imgerror=true
    fi
    sed -i '$d' /tmp/img0 # remove last line
fi
paste -d '' /tmp/img0 <(printf "\n${BOLD}") > /tmp/img # in case title overflows to 2nd line

printf "${BOLD}${titleList[$choice]} (${yearList[$choice]:=-})${NRM}" | tr -d '\n' > /tmp/mvinfo
if [ "$description" = "Rotten Tomatoes every day." ] || [ "$description" = "You're almost there! Just confirm how you got your ticket." ]; then
    printf "\n${NRM}-\n" >> /tmp/mvinfo
else
    printf "\n${NRM}${description:=-}\n" >> /tmp/mvinfo
fi

printf "\n${BOLD}Language${NRM}: ${language:=-}\n" >> /tmp/mvinfo
printf "${BOLD}Director${NRM}: ${director:=-}\n" >> /tmp/mvinfo
printf "${BOLD}Runtime${NRM}: ${runtime:=-}\n" >> /tmp/mvinfo
printf "${BOLD}Genre${NRM}: ${genre:=-}\n\n" >> /tmp/mvinfo

if [ -n "$tomatoscore" ]; then
    printf "${RED}Tomatometer${NRM}: $tomatoscore%%\n" >> /tmp/mvinfo
else
    printf "${RED}Tomatometer${NRM}: -\n" >> /tmp/mvinfo
fi
if [ $audiencescore ]; then
    printf "${BOLD}Audience Score${NRM}: $audiencescore%%\n" >> /tmp/mvinfo
else
    printf "${BOLD}Audience Score${NRM}: -\n" >> /tmp/mvinfo
fi

fold -s -w $txtwidth /tmp/mvinfo > /tmp/mvinfostd
printf "\n${BOLD}Visit${NRM}: ${linkList[choice]}\n"
if [ "$imgerror" = true ]; then # In case of imgerror no image
    cp /tmp/mvinfostd /tmp/output
else
    sed -e 's/$/\t/' -i /tmp/img
    linesart=$(cat /tmp/img | wc -l)
    linestxt=$(cat /tmp/mvinfostd | wc -l)
    i=$((linestxt-linesart))
    while (( i > 0 ))
    do
        printf "%*s\t\n" $asciiwidth ' ' >> /tmp/img
        ((i--))
    done
    paste -d '' /tmp/img /tmp/mvinfostd > /tmp/output
fi
cat /tmp/output

# Clear temporary files
rm /tmp/img.jpg /tmp/img /tmp/img0 /tmp/mvinfo /tmp/mvinfostd /tmp/output