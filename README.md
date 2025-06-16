# movieinfo: ***Get movie info in the terminal***
![Screenshot](screenshots/screenshot_chafa.png)

# Dependencies
`chafa`: for default mode <br />
`ascii-image-converter`: for ASCII [--ascii] or Braille [--braille] mode <br />
`catimg`: for catimg mode [--catimg] <br />
**None**: for no image mode [--no-image]

# Installation
To install for the current user, run:

```bash
mkdir -p "$HOME/.local/bin"
curl https://raw.githubusercontent.com/gmou3/movieinfo/main/movieinfo.sh -o "$HOME/.local/bin/movieinfo"
chmod +x "$HOME/.local/bin/movieinfo"
```

(Alternatively, you can simply download and run the script `movieinfo.sh`.)

# Usage
movieinfo [flags]

The default image previewer is `chafa`.

flags: <br />
   --ascii: ASCII image using `ascii-image-converter` <br />
   --braille: Braille image using `ascii-image-converter -b` <br />
   --catimg: image using `catimg` <br />
   --no-image: no image
