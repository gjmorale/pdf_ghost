
PDF::Reader::PageTextReceiver.class_eval do
	SPACE = " "

	def internal_show_text(string)
        if @state.current_font.nil?
          raise PDF::Reader::MalformedPDFError, "current font is invalid"
        end
        glyphs = @state.current_font.unpack(string)
        total_text = "" #EDIT
        total_width = 0 #EDIT
        newx, newy = @state.trm_transform(0,0)
        prev_space = false #EDIT
        glyphs.each_with_index do |glyph_code, index|
          # paint the current glyph
          utf8_chars = @state.current_font.to_utf8(glyph_code)

          # apply to glyph displacment for the current glyph so the next
          # glyph will appear in the correct position
          glyph_width = @state.current_font.glyph_width(glyph_code) / 1000.0
          th = 1
          total_width += glyph_width * @state.font_size * th #EDIT
          unless prev_space and utf8_chars == SPACE
          	total_text << utf8_chars #EDIT
          end
          prev_space = (utf8_chars == SPACE) #EDIT
          @state.process_glyph_displacement(glyph_width, 0, utf8_chars == SPACE)
        end
        unless string.match /^\d{6}\s[A-Z0-9]{8}\s\d{6}$/ #Morgan Stanley vertical code remover
          @characters << PDF::Reader::TextRun.new(newx*2, newy*2, total_width, @state.font_size, total_text) #EDIT
        end
    end

end




PDF::Reader::PageLayout.class_eval do
  def initialize(runs, mediabox)
      raise ArgumentError, "a mediabox must be provided" if mediabox.nil?

      @runs    = merge_runs(runs)
      @mean_font_size   = mean(@runs.map(&:font_size)) || 0
      @mean_glyph_width = mean(@runs.map(&:mean_character_width)) || 0
      @page_width  = (mediabox[2] - mediabox[0])*2 #EDIT
      @page_height = (mediabox[3] - mediabox[1])*2 #EDIT
      @x_offset = @runs.map(&:x).sort.first
      @current_platform_is_rbx_19 = RUBY_DESCRIPTION =~ /\Arubinius 2.0.0/ &&
                                      RUBY_VERSION >= "1.9.0"
    end

    def to_s
      return "" if @runs.empty?

      wildchar = '¶'
      page = row_count.times.map { |i| wildchar * col_count }
      @runs.each do |run|
        x_pos = ((run.x - @x_offset) / col_multiplier).round
        y_pos = row_count - (run.y / row_multiplier).round
        if y_pos < row_count && y_pos >= 0 && x_pos < col_count && x_pos >= 0
          local_string_insert(page[y_pos], run.text, x_pos)
        end
      end
      interesting_rows(page).map(&:rstrip).join("\n")
    end

    private

    # take a collection of TextRun objects and merge any that are in close
    # proximity
    def merge_runs(runs) #EDIT
      runs.group_by { |char|
        (char.y*100).to_i
      }.map { |y, chars|
        chars
        #group_chars_into_runs(chars.sort)
      }.flatten.sort
    end
end
