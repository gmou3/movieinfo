#!/bin/bash

read -p "Search: " movie
movie=$(echo $movie | sed -r 's/[ ]+/%20/g')
content=$(wget https://www.rottentomatoes.com/search?search=$movie -q -O -)
readarray movies -t <<< $(echo $content | grep -oP '(?<=<search-page-media-row).*?(?=</search-page-media-row>)')
readarray titleList -t <<< $(echo ${movies[@]} | grep -oP '(?<=slot="title">).*?(?= </a>)')
readarray yearList -t <<< $(echo ${movies[@]} | grep -oP '(?<=releaseyear=").*?(?=")')
readarray linkList -t <<< $(echo ${movies[@]} | grep -oP '(?<=<a href=").*?(?=" class="unset" data-qa="thumbnail-link" slot="thumbnail">)')

echo "Choose film:"
for i in $(seq 0 5);
do
    if [ "${titleList[$i]}" ]; then
        echo -n "  "$i
        echo -n ". "
        echo -n ${titleList[$i]}
        echo -n " ("
        echo -n ${yearList[$i]}
        echo ")"
    fi
done
read -p "Choice: " choice

# Print Movie Info
content=$(wget ${linkList[choice]} -q -O -)
thumbnail=$(echo $content | grep -oP '(?<=<meta property="og:image" content=").*?(?=">)')
wget -q $thumbnail -O /home/giorgos/Documents/apps/thumbnail.jpg
asciiart -c -i -w 20 /home/giorgos/Documents/apps/thumbnail.jpg
description=$(echo $content | grep -oP '(?<=description":").*?(?=",")' | head -1)
echo $description
genre=$(echo $content | grep -oP '(?<="genre":[").*?(?="])')
echo $genre
tmp=$(echo $content | grep -oP '(?<=<score-board-deprecated).*?(?=</score-board-deprecated>)')
tomatoscore=$(echo $tmp | grep -oP '(?<=tomatometerscore=").*?(?=")')
audiencescore=$(echo $tmp | grep -oP '(?<=audiencescore=").*?(?=")')
echo tomatoscore: $tomatoscore, audiencescore: $audiencescore
rm /home/giorgos/Documents/apps/thumbnail.jpg