# movieinfo
Get movie info in the terminal
![Screenshot](screenshot.png)

# Dependencies
asciiart  (for default mode) <br />
catimg  (for realistic [-r] mode) <br />
 —  (for no image [-n] mode)

# Installation
To install systemwide, run:

    sudo wget https://raw.githubusercontent.com/gmou3/movieinfo/main/movieinfo.sh -O /usr/bin/movieinfo
    sudo chmod a+rx /usr/bin/movieinfo
(Alternatively, you can simply download and run the script `movieinfo.sh`.)

# Usage
movieinfo [flags]

flags: <br />
   -r: realistic image using catimg (instead of default asciiart) <br />
   -n: no image
