# movieinfo
**Get movie info in the terminal**
![Screenshot](screenshots/screenshot_chafa.png)

# Dependencies
`chafa`: for default mode <br />
`catimg`: for catimg mode [--catimg] <br />
`asciiart`: for ASCII art mode [--asciiart] <br />
**None**: for no image mode [--no-image]

# Installation
To install systemwide, run:

    sudo wget https://raw.githubusercontent.com/gmou3/movieinfo/main/movieinfo.sh -O /usr/bin/movieinfo
    sudo chmod a+rx /usr/bin/movieinfo
(Alternatively, you can simply download and run the script `movieinfo.sh`.)

# Usage
movieinfo [flags]

flags: <br />
   --catimg: image using catimg <br />
   --asciiart: ASCII art image using `asciiart` <br />
   --no-image: no image
