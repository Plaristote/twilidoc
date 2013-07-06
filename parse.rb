require 'twilidoc_string'
require 'twilidoc_hash'

class ClassParser
  attr_accessor :expressions

  class Attribute
    include HashInitialize
    attr_accessor :start, :type_qualifiers, :type, :name, :template_params
    attr_accessor :doc
  end

  class Method < Attribute
    attr_accessor :qualifiers, :params
    attr_accessor :scope_begin, :scope_end
  end

  class Object
    include HashInitialize
    attr_accessor :name, :type, :inherits, :template_params
    attr_accessor :methods, :attributes, :objects, :enums, :typedefs
    attr_accessor :doc
    attr_accessor :scope_begin, :scope_end

    def initialize
      @methods    = []
      @attributes = []
      @objects    = []
      @enums      = []
      @typedefs   = []
    end

    def merge_namespaces
      i = 0
      while i < objects.size
        if objects[i][:item].type == :namespace
          ii = i + 1
          while ii < objects.size
            if (objects[ii][:item].type == :namespace) and (objects[ii][:item].name == objects[i][:item].name)
              [ :methods, :attributes, :objects, :enums, :typedefs ].each do |items|
                eval "objects[i][:item].#{items} += objects[ii][:item].#{items}"
              end
              objects.delete_at ii
            end
            ii += 1
          end
        end
        objects[i][:item].merge_namespaces
        i += 1
      end
    end

    def solve_type symbol
      parts = (symbol.split '::')
      objects.each do |object|
        if object[:item].name == parts.first
          if parts.size == 1
            return object[:item]
          else
            return object[:item].solve_type (parts[1..parts.size].join '::')
          end
        end
      end
      nil
    end
  end

  class Typedef
    include HashInitialize
    attr_accessor :type, :name
  end

  class Enum
    attr_accessor :name, :flags, :scope_begin, :scope_end
  end

  class Expression
    attr_accessor :words, :type_qualifiers, :type, :name, :qualifiers, :params, :start
    attr_accessor :scope_begin, :scope_end

    def initialize start_it
      @words           = []
      @start           = start_it
      @type_qualifiers = []
      @type            = String.new
      @name            = String.new
      @params          = String.new
      @qualifiers      = []
    end

    def evaluate visibility
      item = case @words.first
      when /^friend$/
        nil
      when /^(public|protected|private):?$/
        visibility = (@words.first.gsub ':', '').to_sym
        @words = @words[1..@words.size]
        return (evaluate visibility)
      when 'typedef'
        evaluate_typedef
      when 'enum'
        evaluate_enum
      when /^(class|struct|namespace)$/
        evaluate_object
      when /^template/
        evaluate_template visibility
      else
        evaluate_member
      end
      if item.class == Array
        item
      else
        [ item, visibility ]
      end
    end

    def evaluate_enum
      enum             = Enum.new
      enum.name        = @words.last unless @words.last == 'enum'
      enum.scope_begin = @scope_begin
      enum.scope_end   = @scope_end
      enum
    end

    def evaluate_typedef
      Typedef.new.init_attrs type: @words[1], name: @words[2]
    end

    def evaluate_object
      return nil if scope_begin.nil? or scope_end.nil?
      hash = {
        scope_begin: scope_begin,
        scope_end:   scope_end,
        type:        @words[0].to_sym,
        name:        @words[1],
        inherits:    []
      }
      if @words[1] =~ /:/
        parts       = @words[1].split ':'
        hash[:name] = parts.first
        @words[1]   = parts.last
      end
      it         = 1
      sep        = false
      visibility = :public
      while it < @words.size
        word = @words[it]
        if sep == false
          if word =~ /:/
            sep        = true
            @words[it] = (word.split ':').join
            @words     = @words[it + 1..@words.size] if @words[it] == ''
            it         = 0
            next
          end
        else
          if word =~ /(public|private|protected|virtual)/
            word       = word.pop if word.last == ','
            visibility = word unless word =~ /virtual/
          else
            word       = word.pop_first if word.first == ','
            word       = word.pop       if word.last  == ','
            hash[:inherits] << ({ visibility: visibility, type: word })
            visibility = :public
          end
        end
        it  += 1
      end
      Object.new.init_attrs hash
    end

    def evaluate_template visibility
      template_params = if @words.first =~ /<(.*)>$/
        tmp    = @words.first.split '<'
        @words = @words[1..@words.size]
        tmp    = tmp[1..tmp.size]
        (tmp.join '<').pop
      else
        result = @words[1].pop_first.pop
        @words = @words[2..@words.size]
        result
      end

      is_specialization     = false
      to_check = if @words[0] =~ /^(class|struct)/
        @words
      else
        i = 0
        while i < @words.size
          break if @words.last == ')'
          i += 1
        end
        if    @words[i]     =~ /^[a-z]+/i
          @words[i..@words.size]
        elsif @words[i - 1] =~ /[a-z]+/i
          @words[(i - 2)..@words.size]
        else
          @words[(i - 1)..@words.size]
        end
      end
      to_check.each do |word|
        if word =~ /^[^(]*(\(\))?<(.*)>[^)]*/
          is_specialization = true
          break
        end
      end

      unless is_specialization
        member                    = evaluate visibility
        member[0].template_params = template_params unless member.nil?
        member
      else
        nil
      end
    end

    def evaluate_member
      it          = 0
      looking_for = :type
      qualifiers  = [ 'const', 'static', 'inline', 'virtual', 'unsigned', 'typename' ]
      while it < @words.size
        word = @words[it]
        if qualifiers.include? word
          if (looking_for == :type) and not [ 'virtual', 'static' ].include? word
            @type_qualifiers << word.to_sym
          else
            @qualifiers << word.to_sym
          end
        elsif looking_for == :type
          while [ '*', '&' ].include? word.last
            @type_qualifiers << (if word.last == '*' then :pointer else :reference end)
            word = word.pop
          end
          @type = word
          looking_for = :name
        elsif looking_for == :name
          while [ '*', '&' ].include? word.first
            @type_qualifiers << (if word.first == '*' then :pointer else :reference end)
            word = word.pop_first
          end
          @name = word
          looking_for = :params
        elsif (looking_for == :params) and word.start_with? '('
          @params = word
        end

        it += 1
      end

      # Constructor or Destructor
      if @name =~ /\(.*\)$/
        @params = @name
        @name   = @type
        @type   = nil
      end

      if @words.join =~ /=0$/
        @qualifiers << :virtual_pure
      end

      hash_params = {
        start: @start, type_qualifiers: type_qualifiers, type: type, name: @name
      }
      if @params != ''
        hash_params.merge! params: @params, qualifiers: @qualifiers, scope_begin: @scope_begin, scope_end: @scope_end
        Method.new.init_attrs    hash_params
      else
        Attribute.new.init_attrs hash_params
      end
    end
  end

  def initialize str
    @code        = str
    @it          = 0
    @expressions = []
    @expression  = nil
  end

  def next_word
    until end_reached?

      if @code[@it] == ';'
        @expression = nil
        @it        += 1
      elsif @code[@it] == '{'
        skip_scope
        @expression = nil
        @it        += 1
        next
      end
      skip_commentary

      break unless [ ' ', "\t", "\n", '#' ].include? @code[@it]
      @it += 1
    end
  end

  def get_word
    skip_commentary
    word_start = @it
    contexts   = []
    delimiters = [ '()', '<>' ]
    spaces     = [ ' ', "\t", "\n", '#', ';', '{' ]
    until end_reached?
      break if (spaces.include? @code[@it]) and (contexts.size == 0)
      skip_string
      skip_commentary
      break if end_reached?

      delimiters.each do |delimiter|
        if (@code[@it] == delimiter[0]) and (@code[word_start..@it] != 'operator<')
          contexts << delimiter[1]
          break
        end
      end

      if @code[@it] == contexts.last
        contexts.pop
      end

      @it += 1
    end

    if word_start != @it
      if @expression.nil?
        @expression      = Expression.new word_start
        @expressions    << @expression
      end
      word               = @code[word_start...@it]
      if word  =~ /\(.*\)$/
        tmp    = word.split '('
        word_1 = tmp.first
        word_2 = '(' + (tmp[1..tmp.size].join '(')
        @expression.words << word_1 << word_2
      else
        @expression.words << word
      end
    end
  end

  def skip_commentary
    if    @code[@it..@it + 1] == '//'
      @it += 1 while @code[@it] != "\n"
      @it += 1
    elsif @code[@it..@it + 1] == '/*'
      @it += 2
      @it += 1 while @code[@it..@it + 1] != '*/'
      @it += 2
    end
  end

  def skip_string
    sep = @code[@it]
    if (sep == '"') or (sep == "'")
      escaped = false
      @it    += 1
      while (@code[@it] != sep) or (escaped == true)
        escaped = (@code[@it]) == "\\" and (escaped == false)
        @it  += 1
        raise @it.to_s if @code[@it] == nil
      end
      @it    += 1
    end
  end

  def skip_scope
    @expression.scope_begin = @it unless @expression.nil?
    bracket_count = 0
    until end_reached?
      if    @code[@it] == '{'
        bracket_count += 1
      elsif @code[@it] == '}'
        bracket_count -= 1
      end
      @it += 1
      break if bracket_count == 0
    end
    @expression.scope_end   = @it unless @expression.nil?
  end

  def end_reached?
    @it >= @code.size
  end

  def probe object = nil
    visibility = :public
    visibility = :private if (not object.nil?) and object.type == :class
    puts 'Probing for expressions and scopes for object' + (if object.nil? then 'global scope' else object.name end) if ACTIVE_LOG == true
    until end_reached?
      next_word
      get_word
    end
    puts 'Finish probind for expressions and scopes' if ACTIVE_LOG == true
    @expressions.each do |expression|
      item = expression.evaluate visibility
      if item.first.class == Object
        scope  = @code[item.first.scope_begin + 1..item.first.scope_end - 2]
        prober = ClassParser.new scope
        prober.probe item.first
      end

      visibility = item.last
      item       = { visibility: item.last, item: item.first }
      case (item[:item].class.name.split ':').last
      when 'Object'    then object.objects    << item
      when 'Method'    then object.methods    << item
      when 'Attribute' then object.attributes << item
      when 'Typedef'   then object.typedefs   << item
      when 'Enum'
        probe_enum item[:item]
        object.enums << item
      end
    end
  end

  def probe_enum enum
    code       = @code[enum.scope_begin + 1..enum.scope_end - 2]
    flags      = code.split ','
    count      = 0
    enum.flags = Array.new
    flags.each do |flag|
      item     = Hash.new
      parts    = flag.split '='
      if parts.size != 1
        item[:name]  = parts.first.gsub /\s/, ''
        item[:value] = parts.last.gsub  /\s/, ''
        count        = item[:value].to_i
      else
        item[:name]  = parts.first
        item[:value] = count
      end
      enum.flags << item
      count += 1
    end
  end

end

