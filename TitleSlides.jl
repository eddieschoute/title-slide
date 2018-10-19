using TextWrap
using CSV

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

output = ```ffmpeg -y -f lavfi -i color=c=white:s=1920x1080:d=5 -i quics-logo-trim.png
-filter_complex "overlay=main_w-overlay_w-40:main_h-overlay_h-40,
drawtext=fontfile=/Library/Fonts/Trebuchet\ MS\ Bold.ttf:fontsize=50:
fontcolor=black:x=100:y=100:text='Workshop on Quantum Machine Learning 2018',
drawtext=fontfile=/Library/Fonts/Trebuchet\ MS.ttf:fontsize=50:
fontcolor=black:x=100:y=150:text='qml2018.umiacs.io
Sept 24-28, 2018',
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

"Merges mp4 movies (via copying -- not encoding) given by the arguments to a file given by output."
function mergeMovies(movie1 :: String, movie2 :: String, output :: String)
	cmdConcat = `ffmpeg -y -i $movie1 -c copy -bsf:v h264_mp4toannexb -f mpegts temp1` &
	`ffmpeg -y -i $movie2 -c copy -bsf:v h264_mp4toannexb -f mpegts temp2` &
	`ffmpeg -f mpegts -i "concat:temp1|temp2" -c copy -bsf:a aac_adtstoasc $output`
	println(cmdConcat)
	output = run(cmdConcat)
end

println("Preparing temp files")
try
	cmdfifo = run(`mkfifo temp1 temp2`)

	# Reads in the csv given by ARGS and processes the lines one by one
	println("Reading input csv")
	for titleRow in CSV.File(inputMovies)
		# titleRow = titleData[i,:]
		println(titleRow)
		# First generate a title slide
		generateTitleMovie(titleRow.title, "$(titleRow.author), $(titleRow.affiliation)")
		# # Then merge title slide and main movie together with transition.
		mergeMovies(titleSlideName, "recordings/$(titleRow.filename).mov", "recordings/$(titleRow.filename)_merged.mov")
	end
catch err
	if isa(err, LoadError)
		# do nothing
		println("Already defined mkfifo")
	else
		rethrow(err)
	end
finally
	run(`rm temp1 temp2`)
end


