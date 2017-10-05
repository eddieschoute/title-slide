# title-slide
Prepend a title slide to a video.

_Note_: The script is very rough on the edges.
You will probably have to read and understand the source code
If you have questions, contact me.

## Installation
1. Install the Julia programming language
1. Install the latest version of ffmpeg
1. Download this repository.

## Usage
1. Prepare an `<input>.csv` containing the following columns without header:
	1. (unused)
	2. Input video filename
	3. Author
	4. Affiliation
	5. Title
1. Run `julia TitleSlides.jl <input>.csv`

## Notes
Currently the following is hard-coded and will need to be changed in the source:

* Conference title
* Logos
