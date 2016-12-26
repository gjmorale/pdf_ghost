class Cleaner


	WILDCHAR = '¶'

	@forbiddens = []
	@forbiddens_raw = []
	@matches = 0
	@last_count = 0

	def execute
		print "Processing"
		files = Dir["#{@input_path}/*/*.pdf"]
		total = files.size
		puts " #{total} files: "
		files.each.with_index do |file, i|
			
			print "[#{i}/#{total}]"
			name = File.basename(file, '.pdf')
	if name.match(/COLMENA1/)
			dir_name = File.dirname(file)
			dir_name = dir_name[dir_name.rindex('/')+1..-1]
			file_name = "#{@output_path}/" << dir_name
			unless File.exist? "#{file_name}"
				Dir.mkdir(file_name) 
			end
			sub_file_name = "#{@output_path}/" << dir_name << "/" << name
			unless File.exist? "#{sub_file_name}"
				Dir.mkdir(sub_file_name) 
				Dir.mkdir("#{sub_file_name}/raw")
			end
			f_input = File.open(file)
			@reader = PDF::Reader.new(f_input)
			n = @reader.pages.size
			step = 0
			@reader.pages.each.with_index do |page, j|
				raw_output = File.open("#{sub_file_name}/raw/#{name}_#{page.number}.raw", "w")
				write(page.raw_content, raw_output, 1)
				receiver = PDF::Reader::PageTextReceiver.new
				page.walk(receiver)
				content = receiver.content
				f_output = File.open("#{sub_file_name}/#{name}_#{page.number}.page",'w')
				write(content, f_output)
				if ( prog = ((j+1)*100)/(n)) >= step
					delta = ((prog-step)/4+1)
					step += 4*delta
					print "."*delta 
				end
			end
			puts "[100%] #{name} (#{@matches - @last_count})"
			@last_count = @matches
	else
		puts name
	end
		end
		puts "#{@matches} elements detected and replaced"
	end

	def write content, file, raw = 0
		new_content = ""
		content.each_line do |line|
			new_content << clean(line, raw)
		end
		file.write(new_content)
	end


	def load (input, output, source )
		print "Loading......"
		@output_path = output
		@input_path = input
		@source_path = source
		File.open(@source_path,'r') do |file|
			@forbiddens = []
			@forbiddens_raw = []
			file.each_line do |line|
				regex = regexify(line.strip!)
				@forbiddens << regex if regex
				regex = regexify(line, true)
				@forbiddens_raw << regex if regex
			end
		end
		print ".."
		@last_count = @matches = 0
		FileUtils.rm_rf(Dir["#{@output_path}/*"])
		puts "...[100%]"
	end

	def regexify term, raw = false
		return nil if term.nil? or term.empty?
		term = Regexp.escape term
		regex = ""
		if raw
			regex << '(' << term << ')' << '(?:.+Tj)'
		else
			skip = true
			term.each_char do |char|
				unless char == WILDCHAR
					regex << "#{WILDCHAR}*" unless skip
					skip = (char == "\\")
					regex << char
				end
			end
		end
		Regexp.new(regex, true)
	end

	def clean line, capture_group = 0
		new_line = line
		forbiddens = capture_group == 1 ? @forbiddens_raw : @forbiddens
		forbiddens.each do |forbidden|
			line.match(forbidden){|m|
				@matches += 1
				xi = m.offset(capture_group)[0]
				xf = m.offset(capture_group)[1]
				start = middle = final = ""
				if xi > 0
					start = new_line[0..xi-1]
				end
				if xi < xf
					middle = '?'*(xf-xi)
				end
				if xf < line.length-1
					final = new_line[xf..-1]
				end
				new_line = start << middle << final
			}
		end
		new_line
	end

end