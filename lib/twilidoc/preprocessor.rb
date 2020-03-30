require 'pathname'

module CppParser
  class Preprocessor
    attr_accessor :source, :inc_pathes, :filemap

    def initialize
      @defines      = Hash.new
      @macros       = Hash.new
      @source       = String.new
      @skipping     = false
      @skip_level   = 0
      @if_level     = 0
      @cur_path     = ''
      @inc_pathes   = []
      @filemap      = []
      @files        = []
    end

    def skipping?
      @skipping == true && @if_level >= @skip_level
    end

    def make_epured_line line
      epured_line = line.dup
      ii = 0
      while ii < line.size
        sep     = line[ii]
        escaped = false
        if (sep == '"') || (sep == "'")
          while (line[ii] != sep) or (escaped == true)
            escaped         = if line[ii] == "\\" then true else false end
            epured_line[ii] = ' '
            ii             += 1
          end
          epured_line[ii] = ' '
        elsif line[ii..ii + 1] == '//'
          (epured_line[ii] = ' ' ; ii += 1) while (line[ii] != "\n") and (line[ii] != nil)
        elsif line[ii..ii + 1] == '/*'
          (epured_line[ii] = ' ' ; ii += 1) while (line[ii..ii + 1] != '*/') and (line[ii] != nil)
          epured_line[ii] = ' '
        end

        ii += 1
      end
      epured_line
    end

    def solve_variables variables, line
      match = false
      begin
        epured_line = make_epured_line line
        match       = false
        variables.each do |key,value|
          epured_line.scan /([^a-z0-9_])#{key}([^a-z0-9_])/ do
            bpos = ($~.offset 1)[1]
            epos = ($~.offset 2)[0]
            if epured_line[bpos] == '#'
              epured_line = epured_line.emplace "\"#{value}\"", bpos - 1, epos
              line        = line.emplace        "\"#{value}\"", bpos - 1, epos
            elsif epured_line[epos..epos + 1] == '##'
              epured_line = epured_line.emplace value, bpos, epos - 1
              line        = line.emplace        value, bpos, epos - 1
            else
              epured_line = epured_line.emplace value, bpos, epos
              line        = line.emplace        value, bpos, epos
            end
            match = true
            break
          end
        end
      end while match == true
      line
    end

    def solve_macros line
      no_macros = true
      match     = false
      begin
        epured_line = make_epured_line line
        match       = false 
        @macros.each do |key,value|
          epured_line.scan /([^a-z0-9_])#{key}(\()/ do
            bpos = $~.offset 1
            epos = $~.offset 2

            p_names  = (value[:params].gsub /\s/, '').split ','
            params   = {}
            iii      = epos[1]
            contexts = []
            start_p  = iii
            while iii < line.size
              if ([ ',', ')' ].include? line[iii]) and (contexts.size == 0)
                params[p_names[params.size]] = line[start_p...iii]
                start_p = iii + 1
              elsif line[iii] == '('
                contexts << ')'
              elsif line[iii] == contexts.last
                contexts.pop
              end
              iii += 1
              break if line[iii - 1] == ')'
            end

            puts ('Solving macro ' + key + " with parameters #{params.inspect}, p_names was #{p_names.inspect}") if  ACTIVE_LOG == true

            line      = line.emplace value[:value], bpos[1], iii
            line      = solve_variables params, line
            match     = true
            no_macros = false
            break
          end
        end
      end while match == true
      line = solve_variables @defines, line
      if no_macros == false
        solve_macros line
      else
        line
      end
    end

    def parse file
      puts '[Preprocessor] Evaluating "' + file + '"' if  ACTIVE_LOG == true
      path        = (File.expand_path file).split '/'
      path        = path[0...path.size - 1].join '/'
      @cur_path   = path
      code        = File.read file
      code        = code.force_encoding 'UTF-8'
      lines       = code.split "\n"
      file_begin  = @source.size
      i           = 0
      while i < lines.count
        line      = lines[i]
        if line[0] == '#' # Preprocessing directive
          i       = read_directive lines, i
          next
        end

        unless skipping?
          line      = solve_macros line
          @source  += line + "\n"
        end

        @cur_path = path
        i        += 1

      end
      filename = Pathname.new file
      if filename.absolute?
	file = filename.relative_path_from (Pathname.new Dir.pwd)
	file = file.to_s
      end
      @filemap << { beg: file_begin, end: @source.size, filename: file }
    end
private
    def read_directive lines, i
      line      = lines[i][1..lines[i].size]
      while line[line.size - 1] == '\\'
        i      += 1
        line    = line[0...line.size - 1] + lines[i]
      end
      line = line.strip
      [ 'define', 'undef', 'include', 'ifndef',
        'ifdef', 'else', 'endif' ].each do |word|
        if line =~ /^#{word}/
          line = line[word.size..line.size].strip
          send "directive_#{word}", line
          break
        end
      end
      i + 1
    end

    def directive_define line
      return if skipping?
      results = line.scan /([a-z0-9_]+)\((([a-z0-9_]+\s*,?\s*)*)\)\s(.*)/i
      if results.nil? or (results == [])
        parts = line.split ' '
        name  = parts[0]
        value = parts[1..parts.size].join ' '
        @defines[name] = value
        puts "Found define #{name} -> #{value}" if ACTIVE_LOG == true
      else
        results = results.first
        name    = results[0]
        params  = results[1]
        value   = results[3]
        @macros[name] = { value: value, params: params }
        puts "Found macro #{name} -> #{value.gsub /\s+/, ' '}" if ACTIVE_LOG == true
      end
    end

    def directive_undef line
      return if skipping?
      @defines.delete line
    end

    def directive_ifndef line
      @if_level  += 1
      return if skipping?
      if @defines.keys.include? line
        @skip_level = @if_level
        @skipping   = true
      end
    end

    def directive_ifdef line
      @if_level += 1
      return if skipping?
      unless @defines.keys.include? line
        @skip_level = @if_level
        @skipping   = true
      end
    end

    def directive_endif line
      @if_level -= 1
      @skipping  = skipping?
    end

    def directive_else line
      @skipping = (not @skipping) if @skip_level == @if_level
    end

    def directive_include line
      return if skipping?
      path = line.scan /^[<"]([a-z\/0-9._-]+)[>"]$/i
      path = path.first.first
      local = @cur_path + '/' + path

      if File.exists? local.to_s
        parse local
      elsif File.exists? path
        parse path
      else
        parsed = false
        @inc_pathes.each do |inc_path|
          from_path = "#{inc_path}/#{path}"
          if File.exists? from_path
             parsed = true
             parse from_path
            break
          end
        end
      end
    end
  end
end
