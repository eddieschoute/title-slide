using TextWrap

const titleSlideName = "title_tmp.mp4"
const inputMovies = ARGS[1]

"""
    generateTitleMovie(title :: String, author :: String)

Generate an mp4 with the title slide for 5 seconds.
Output file will be called according to [`titleSlideName`](@ref).
"""
function generateTitleMovie(title :: String, author :: String)
	println(title)
	println(author)
	# 24 w character width
	titleWrap = wrap(title; width = 35)

	# Move georgia tech logo up halfway to quics logo
output = ```ffmpeg -y -f lavfi -i color=c=white:s=1920x1080:d=5 -i georgia-tech-logo.png -i quics-logo-trim.png
-filter_complex "overlay=40:main_h-overlay_h/2-236/2-40,overlay=main_w-overlay_w-40:main_h-overlay_h-40,
drawtext=fontfile=/Library/Fonts/Trebuchet\ MS\ Bold.ttf:fontsize=50:
fontcolor=black:x=100:y=100:text='4th International Conference on Quantum Error Correction',
drawtext=fontfile=/Library/Fonts/Trebuchet\ MS.ttf:fontsize=50:
fontcolor=black:x=100:y=150:text='www.qec2017.org (#qec17)
Sept 11-15, 2017',
drawtext=fontfile=/Library/Fonts/Trebuchet\ MS\ Bold.ttf:fontsize=90:
fontcolor=black:x=100:y=300:text='$titleWrap',
drawtext=fontfile=/Library/Fonts/Trebuchet\ MS.ttf:fontsize=50:
fontcolor=black:x=140:y=600:text='$author'"
$titleSlideName```

	# Run the script
	out = run(output)
	println(output)
	println(out)
end

try
	cmdfifo = run(`mkfifo temp1 temp2`)
catch err
	if isa(err, LoadError)
		# do nothing
		println("Already defined mkfifo")
	end
end

"Merges mp4 movies (via copying -- not encoding) given by the arguments to a file given by output."
function mergeMovies(movie1 :: String, movie2 :: String, output :: String)
	cmdConcat = `ffmpeg -y -i $movie1 -c copy -bsf:v h264_mp4toannexb -f mpegts temp1` &
	`ffmpeg -y -i $movie2 -c copy -bsf:v h264_mp4toannexb -f mpegts temp2` &
	`ffmpeg -f mpegts -i "concat:temp1|temp2" -c copy -bsf:a aac_adtstoasc $output`
	println(cmdConcat)
	output = run(cmdConcat)
	println(output)
end

# Reads in the csv given by ARGS and processes the lines one by one
titleData = readcsv(inputMovies, String)
for i = 1:size(titleData,1)
	titleRow = titleData[i,:]
	# First generate a title slide
	generateTitleMovie(titleRow[5], "$(titleRow[3]), $(titleRow[4])")
	# Then merge title slide and main movie together with transition.
	mergeMovies(titleSlideName, "$(titleRow[2]).mp4", "$(titleRow[2])_merged.mp4")
end
