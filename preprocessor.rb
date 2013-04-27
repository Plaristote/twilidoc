require 'pathname'

module CppParser
  class Preprocessor
    attr_accessor :source, :inc_pathes, :filemap

    def initialize
      @defines      = Hash.new
      @source       = String.new
      @skipping     = false
      @skip_level   = 0
      @if_level     = 0
      @cur_path     = ''
      @inc_pathes   = []
      @filemap      = []
    end

    def skipping?
      @skipping == true && @if_level >= @skip_level
    end

    def parse file
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
	@defines.each do |key,value|
          next
	  parts    = key.split '('
	  is_macro = parts.size > 1
	  if is_macro
	    macro  = parts[0]
	    params = parts[1..parts.size].join '('
	    if line =~ macro
	      puts "Found a macro to use"
	      exit 0
	    end
	  else
	    old = line.dup
	    line.gsub! /#{key}/, "#{value}"
	    if old != line
	      puts "Line has been modified with macro:\n\t#{old}\n\t#{line}\n\n"
	    end
	  end
	end
        @source  += line + "\n" unless skipping?
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
      parts = line.split ' '
      name  = parts[0]
      value = parts[1..parts.size].join ' '
      @defines[name] = value
      puts "Found define #{name} -> #{value}"
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
