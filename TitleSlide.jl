module TitleSlide
	doc = """Title Slide generator

	Adds a title slide to the input video containing the title, author and date.
	Optionally also includes the subtitle, a date and a logo.

	Usage:
	  TitleSlide.jl [options] <title> <author> <video> [<logo> ...]

	Options:
	  -d <date>, --date=<date>  Include the given date. Must be ISO 8601 formatted, e.g. 2019-12-31. Overrides --today flag.
	  -o <file>, --output=<file>  Set the output file, defaults to postfixing "_title" to the file name.
	  -s <subtitle>, --subtitle=<subtitle>  Add a subtitle above the date.
	  -t, --today  Include today's date.
	  -s <series>, --series=<series>  Set the seminar series.
	"""

	using TextWrap
	using CSV
	using DocOpt
	import Dates

	function main()
		args = docopt(doc)
		@show args

		date :: Union{Dates.Date, Nothing} = nothing
		if args["--today"]
			println("Using today's date")
			date = Dates.today()
		end
		if args["--date"] != nothing
			println("Adding specific date")
			date = Dates.Date(args["--date"], "y-m-d")
		end
		@show date

		@show input_file = args["<video>"]
		if !isfile(input_file)
			throw(ArgumentError("The input file '$input_file' cannot be found"))
		end
		(input_base, input_ext) = splitext(input_file)
		if args["--output"] != nothing
			output_file = args["--output"]
		else
			if input_ext == ""
				throw(ArgumentError("The input movie does not have an extension"))
			end
			output_file = "$(input_base)_merged$input_ext"
			if isfile(output_file)
				println("The default output file '$output_file' already exists! Stopping to prevent data loss.")
				return 0
			end
		end
		@show output_file


		# Generate the title slide
		titleSlide_file = generateTitleMovie(
			args["<title>"], args["<author>"],
			# Remove the dot from extension
			input_ext[2:end],
			series=args["--series"],
			subtitle=args["--subtitle"],
			date=date)
		@show titleSlide_file

		# Concatenate the title slide file to the input movie, and create output
		mergeMovies(titleSlide_file, input_file, output_file)

		# Clean up temp files
		rm(titleSlide_file)
	end


	"""
	    generateTitleMovie(title :: String, author :: String)

	Generate an mp4 with the title slide for 5 seconds.
	Output file will be called according to [`titleSlideName`](@ref).
	"""
	function generateTitleMovie(title :: String, author :: String,
		output_format :: String;
		series :: Union{String, Nothing} = nothing,
		subtitle :: Union{String, Nothing} = nothing,
		date :: Union{Dates.Date, Nothing} = nothing)

		# Place the quics logo.
		filter_commands = String["overlay=main_w-overlay_w-40:main_h-overlay_h-40"]
		@show series
		if series != nothing
			push!(filter_commands, "drawtext=fontfile=/Library/Fonts/Trebuchet MS Bold.ttf:fontsize=50:fontcolor=black:x=100:y=100:text='$series'")
		end

		if subtitle != nothing || date != nothing
			subtitle_array = String[]
			if subtitle != nothing
				push!(subtitle_array, subtitle)
			end
			if date != nothing
				push!(subtitle_array, string(date))
			end
			subtitles :: String = join(subtitle_array, "\n")
			push!(filter_commands, "drawtext=fontfile=/Library/Fonts/Trebuchet MS.ttf:fontsize=50:fontcolor=black:x=100:y=150:text='$subtitles'")
		end

		# 24 w character width
		titleWrap = wrap(title; width = 35)
		push!(filter_commands, "drawtext=fontfile=/Library/Fonts/Trebuchet MS Bold.ttf:fontsize=90:fontcolor=black:x=100:y=300:text='$titleWrap'")
		push!(filter_commands, "drawtext=fontfile=/Library/Fonts/Trebuchet MS.ttf:fontsize=50:fontcolor=black:x=140:y=600:text='$author'")

		@show filter_commands
		(file, io) = mktemp()
		close(io)
		@show file
		output = ```ffmpeg -y -f lavfi -i color=c=white:s=1920x1080:d=5:rate=59.940 -i quics-logo-trim.png
		-filter_complex $(join(filter_commands, ","))
		-f $(output_format) $file```

		# Run the script
		run(output)
		return file
	end

	"Merges mp4 movies (via copying -- not encoding) given by the arguments to a file given by output."
	function mergeMovies(movie1 :: String, movie2 :: String, output :: String)
		temp1 = tempname()
		temp2 = tempname()
		try
			cmdfifo = run(`mkfifo $temp1 $temp2`)
			cmdConcat = `ffmpeg -y -i $movie1 -c copy -bsf:v h264_mp4toannexb -f mpegts $temp1` &
			`ffmpeg -y -i $movie2 -c copy -bsf:v h264_mp4toannexb -f mpegts $temp2` &
			`ffmpeg -y -f mpegts -i "concat:$temp1|$temp2" -c copy $output`
			println(cmdConcat)
			run(cmdConcat)
			rm(temp1)
			rm(temp2)
		catch err
			if isa(err, LoadError)
				# do nothing
				println("FIFO files already exist.")
			else
				rethrow(err)
			end
		end
	end
end

TitleSlide.main()
