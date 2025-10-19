#!/bin/bash

img_viewer=chafa  # default

# Text formatting
BOLD='\e[1m'
RED='\e[1;31m'
BLUE='\e[1;34m'
YLLW='\e[1;33m'
NRM='\e[0m'  # normal

# Check args
no_img=false
for arg in "$@"; do
    case $arg in
    --catimg)
        img_viewer=catimg
        ;;
    --ascii)
        img_viewer=ascii-image-converter
        ;;
    --braille)
        img_viewer=ascii-image-converter
        flags=-b
        ;;
    --no-image)
        img_viewer=""
        no_img=true
        ;;
    *)
        printf "${BOLD}Usage${NRM}: movieinfo [flags]\n\n\
The default image previewer is \`chafa\`.\n\n\
${BOLD}flags${NRM}:\n\
    --ascii: ASCII image using \`ascii-image-converter\`\n\
    --braille: Braille image using \`ascii-image-converter -b\`\n\
    --catimg: image using \`catimg\`\n\
    --no-image: no image\n"
        exit
        ;;
    esac
done

# Warn if image viewer is unavailable
if [ "$no_img" = false ] && [ -z "$(command -v $img_viewer)" ]; then
    printf "${YLLW}WARNING${NRM}: ${img_viewer} is not installed.\n"
    img_viewer=""
    no_img=true
fi

# Read movie and search
printf "${BOLD}Search${NRM}: "
read movie
movie=$(echo "$movie" | sed -r 's/ /%20/g')
content=$(curl -s https://www.rottentomatoes.com/search?search=$movie)
readarray movies -t <<< $(echo $content | grep -oP \
'(?<=<search-page-media-row).*?(?=</search-page-media-row>)')
readarray titleList -t <<< $(echo ${movies[@]} | grep -oP \
'(?<=slot="title"> ).*?(?= </a>)' | sed "s/&#39;/'/g" | sed 's/&amp;/\&/g')
readarray yearList -t <<< $(echo ${movies[@]} | grep -oP \
'(?<=release-year=").*?(?=")')
readarray linkList -t <<< $(echo ${movies[@]} | grep -oP \
'(?<= </a> <a href=").*?(?=" class="unset" data-qa="info-name" slot="title">)')

# Movie choice dialog
if [ ${#titleList[$i]} != 1 ]; then
    printf "${BOLD}Choose movie${NRM}:\n"
else
    printf "${BOLD}No results.${NRM}\n"
    exit
fi
moviesNum=${#titleList[@]}
for i in $(seq 0 $((moviesNum < 8 ? moviesNum - 1 : 7))); do
    printf "  ${BLUE}$i${NRM}. ${titleList[$i]} (${yearList[$i]:=-})" | tr -d '\n'
    printf '\n'
done

# Read and check choice
chosen=false
i=$((moviesNum < 8 ? moviesNum - 1 : 7))
while [ "$chosen" = false ]; do
    printf "${BOLD}Choice (${BLUE}0${NRM}${BOLD})${NRM}: "
    read choice
    if [ -z $choice ]; then  # default choice
        choice='0'
        chosen=true
    elif [ "$choice" = 'e' ]; then
        exit
    elif [ "$choice" = 'm' ]; then  # more movies
        ((i++))
        if [ ${#titleList[$i]} != 0 ]; then
            printf "${BOLD}Printing more...${NRM}\n"
            while [ ${#titleList[$i]} != 0 ]; do
                printf "  ${BLUE}$i${NRM}. ${titleList[$i]} " | tr -d '\n'
                printf "(${yearList[$i]:=-})" | tr -d '\n'
                printf '\n'
                ((i++))
            done
        else
            printf "No more results.\n"
        fi
        ((i--))
    elif [[ $choice =~ ^[0-9]+$ ]] && [ $choice -le $i ]; then
        chosen=true
    else
        printf "${RED}ERROR${NRM}: Invalid choice. (Type '${BOLD}m${NRM}' "
        printf "for more results or '${BOLD}e${NRM}' to exit.)\n"
    fi
done

# Retrieve chosen movie info
content=$(curl -s ${linkList[$choice]})

tmp=$(mktemp -u XXXXXXXXXX)  # substring for temporary files
img="/tmp/movieinfo_${tmp}_img"
if [ "$no_img" = false ]; then
    img_link=$(echo $content | grep -oP '(?<=<meta property="og:image" content=").*?(?=")' | head -1)
    curl -s "$img_link" -o "$img"
fi

description=$(echo $content | grep -oP '(?<="synopsis-value">).*?(?=</rt-text>)' |
sed 's/&quot;/"/g' | sed "s/&#39;/'/g" | sed 's/&amp;/\&/g' | head -1)
language=$(echo $content | grep -oP \
'(?<=Language</rt-text> </dt> <dd data-qa="item-value-group"> <rt-text data-qa="item-value">).*?(?=</rt-text>)')
director=$(echo $content | grep -oP '(?<="director":\[{"@type":"Person","name":").*?(?=")')
runtime=$(echo $content | grep -oP \
'(?<=Runtime</rt-text> </dt> <dd data-qa="item-value-group"> <rt-text data-qa="item-value">).*?(?=</rt-text>)')
genre=$(echo $content | grep -oP '(?<="metadataGenres":\[").*?(?=")' | head -1)
tomatometer=$(echo $content | grep -oP '(?<=s","scorePercent":").*?(?=%","title":"Tomatometer")' | head -1)
popcornmeter=$(echo $content | grep -oP '(?<="scorePercent":").*?(?=%","title":"Popcornmeter")' | head -1)

# Print chosen movie info
printf "\n${BOLD}Visit${NRM}: ${linkList[choice]}\n"

termwidth=$(tput cols)  # terminal width
termheight=$(tput lines)  # terminal height
asciiwidth=$((27 * termwidth / 100))
txtwidth=$((6 * termwidth / 10))

if [ "$img_viewer" = "chafa" ]; then
    chafa -s "$((termwidth))x$((termheight / 3))" "$img"
    printf "\n"
elif [ "$img_viewer" = "catimg" ]; then
    catimg -r 2 -w $((2 * $asciiwidth)) "$img" &>> "${img}-0"
    if [ "$(cat "${img}-0" | grep error)" ]; then
        # In case of catimg error no image
        no_img=true
    fi
    sed -i '$d' "${img}-0"  # remove last line
    # In case title overflows to 2nd line
    paste -d '' "${img}-0" <(printf "\n${BOLD}") > "${img}-final"
elif [ "$img_viewer" = "ascii-image-converter" ]; then
    script -q -c "ascii-image-converter $flags -C -W $asciiwidth $img" -O /dev/null >> "${img}-0"
    if [ "$(cat "${img}-0" | grep ascii-image-converter)" ]; then
        # In case of ascii-image-converter error no image
        no_img=true
    fi
    sed -i 's/\r//g' "${img}-0"  # dos to unix
    # In case title overflows to 2nd line
    paste -d '' "${img}-0" <(printf "\n${BOLD}") > "${img}-final"
fi

if [ "$no_img" = true ] && [ -n "$img_viewer" ]; then
    printf "${RED}ERROR${NRM}: could not process movie image.\n"
fi

info="/tmp/movieinfo_${tmp}_info"
printf "${BOLD}${titleList[$choice]} (${yearList[$choice]:=-})${NRM}" | tr -d '\n' > "$info"
printf "\n${NRM}${description:=-}\n" >> "$info"

printf "\n${BOLD}Language${NRM}: ${language:=-}\n" >> "$info"
printf "${BOLD}Director${NRM}: ${director:=-}\n" >> "$info"
printf "${BOLD}Runtime${NRM}: ${runtime:=-}\n" >> "$info"
printf "${BOLD}Genre${NRM}: ${genre:=-}\n\n" >> "$info"

meter=$([ -n "$tomatometer" ] && echo "$tomatometer%%" || echo "-")
printf "${RED}Tomatometer${NRM}: ${meter}\n" >> "$info"
meter=$([ -n "$popcornmeter" ] && echo "$popcornmeter%%" || echo "-")
printf "${BOLD}Popcornmeter${NRM}: ${meter}\n" >> "$info"

fold -s -w $txtwidth "$info" > "${info}-std"
if [ "$img_viewer" = "chafa" ] || [ "$no_img" = true ]; then
    cp "${info}-std" "${info}-final"
else
    sed -e 's/$/    /' -i "${img}-final"
    linesart=$(cat "${img}-final" | wc -l)
    linestxt=$(cat "${info}-std" | wc -l)
    i=$((linestxt - linesart))
    while ((i > 0)); do
        printf "%*s    \n" $asciiwidth ' ' >> "${img}-final"
        ((i--))
    done
    paste -d '' "${img}-final" "${info}-std" > "${info}-final"
fi
cat "${info}-final"

# Clear temporary files
rm -f "$img" "${img}-0" "${img}-final"
rm "$info" "${info}-std" "${info}-final"
