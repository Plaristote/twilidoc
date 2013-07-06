def di indent
  indent.times { print ' ' }
end

COLORS = { black: 30, red: 31, green: 32, brown: 33, blue: 34, magenta: 35, cyan: 36, gray: 37 }

class Shell
  COLORS     = { black: 30, red: 31, green: 32, yellow: 33, blue: 34, purple: 35, cyan: 36, white: 37 }
  BACKGROUND = { black: 40, red: 41, green: 42, yellow: 53, blue: 44, purple: 45, cyan: 46, white: 47 }

  def self.get_str_color effects = []
    str = ''
    effects.each do |effect|
      code = if effect[:type] == :background
        BACKGROUND[effect[:color]]
      else
        COLORS[effect[:color]]
      end
      str += ';' if str.size > 0
      str += code.to_s
    end
    get_reset + "\033[#{str}m"
  end

  def self.get_reset
    "\033[0m"
  end
end

def twilart
  r           = Shell.get_str_color([{color: :black, type: :color}])
  atom        = Shell.get_str_color([{color: :green, type: :color}])
  twiley_skin = Shell.get_str_color([{color: :cyan,   type: :background},  {color: :black, type: :color}])
  twiley_hair = Shell.get_str_color([{color: :purple, type: :background},  {color: :black, type: :color}])
  vest        = Shell.get_str_color([{color: :white,  type: :background},  {color: :black, type: :color}])
  glasses     = Shell.get_str_color([{color: :red, type: :background},  {color: :black, type: :color}])

  a = atom
  s = twiley_skin
  h = twiley_hair
  v = vest
  g = glasses

print "
#{r}````````````````````````````````````````````````````````````````````````````````````````````````````
``````````````````````````````````````````````````#{a}......#{r}````````````````````````````````````````````
```````````````````````````````````````````````#{a}..#{r}```````#{a}...#{r}`````````````````````````````````````````
``````````````````````````````````````````````#{a}.#{r}````````````#{a}-.#{r}```````````````````````````````````````
``````````````````````````````````````````#{a}.---#{r}``````````````#{a}..#{r}``````````````````````````````````````
```````````````````````````````````````` #{a}.----#{r}```````````````#{a}..#{r}`````````````````````````````````````
``````````````````````````````````````````#{a}-...#{r}``#{s}.#{r}`````````````#{a}..#{r}````````````````````````````````````
`````````````````````````````````````````#{a}..#{r}`````#{s}--.#{r}````````````#{a}-.#{r}```````````````````````````````````
`````````````````````````````````````````#{a}-#{r}``````.#{s}-::#{r}````````````#{a}-#{r}```````````````````````````````````
```````````````````#{a}.........#{r}````````````#{a}-#{r}````#{h}:oyho#{s}-//-#{r}``````````#{a}.-#{r}``````````````````````````````````
````````````````#{a}..#{r}````````````#{a}.....#{r}````#{a}.-#{r}``#{h}-ydmmmd#{s}/-+ss:#{h}-.#{r}```````#{a}-.#{r}`````````````````````````````````
``````````````#{a}..#{r}````````````````````#{a}...-.#{r}`#{h}-hmmmmmmh#{s}/yy#{h}oshhyo+/:-#{r}.#{a}---#{r}``````#{a}....-----------..#{r}`````````
````````````#{a}.--..#{r}`````````````````````#{a}.-#{r}`#{a}.#{h}hmmmmmmmdhsoydmmmmmmmo#{s}---/#{a}..--....#{r}`````````````#{a}.---.#{r}``````
`````````` #{a}.-----#{r}```````````````````` #{a}-.#{r}`#{h}-mmmmhdddhsoydmmmmmmmh#{s}----o#{a}.#{r}```````````````````````#{a}.:.#{r}`````
````````````#{a}..-..#{r}`````````````````````#{a}-#{r}``#{h}-dyoy#{g}/#:#{h}osoosso/+yhdmd/#{s}---+o#{r}`````````````````````````#{a}./#{r}`````
``````````````#{a}..#{r}`````````````````````#{a}..#{r}```-`#{g}/o:-+yy#{s}soo#{g}/--:+ydy+#{s}--+o#/#{a}-#{r}`````````````````````````#{a}/#{r}`````
```````````````#{a}-#{r}```````````````````` #{a}-#{r}.`````#{g}/o:/oo/ooo/:-/syo#{s}++++o#{h}y#{a}.:#{r} ```````````````````````#{a}-:#{r}`````
````````````````#{a}.#{r}````````````````````#{a}-#{r}``````#{a}.:#{s}:-----:#{g}/++++/#{s}-:++++#{h}ds#{r}`#{a}:#{r}```````````````````````#{a}./.#{r}`````
`````````````````#{a}-#{r}```````````````````#{a}-#{r} ```#{a}....#{s}:-------------:+++#{h}om/#{r} #{a}:.#{r}`````````````````````#{a}./.#{r}``````
``````````````````#{a}-#{r}`````````````````#{a}.-#{r}`#{a}....#{r}````#{s}.------------++++#{h}yN:#{r} #{a}:-#{r}````````````````````#{a}./.#{r}```````
```````````````````#{a}..#{r}`````#{h}.-/oooo+/#{a}---.#{r}``````````#{s}......-.-:oo/+#{h}hmN:#{a}-:-#{r}```````````````````#{a}-:#{r}`````````
````````````````````#{a}.-#{r}``#{h}-ohmmdhyssyyhs:#{r}```````````````#{v} `s+/oyy#{h}dmmN#{r}``#{a}-:.#{r}`````````````#{a}.-:-/-#{r}``````````
``````````````````````#{a}-#{h}smmdhssyhhhhysshs.#{r}````````````#{v}  #{h}smmmmmmmmmN.#{r}`#{a}./.:-#{r}```````````#{a}/////#{r}```````````
`````````````````````#{h}.hmmdsshddmmNNmmhsho#{r}````````````#{v} `#{h}ydddmmddddd:#{r}`#{a}./ `.:-#{r}`````````#{a}////-#{r}```````````
``````````````````  `#{h}dmmdoydmmmmNNNyyyy::#{r}```````````#{v}  #{h}sssyddhhyyhh.#{r}`#{a}./#{r}````#{a}.:-#{r}`````#{a}-:.#{r}```````````````
`````````````````````#{h}yhmsyosdmdysy/#{r}`#{a}.#{r}`#{v}               `#{h}dhhyysosdmh.#{r}``#{a}./#{r}``````#{a}.:-.::.#{r}`````````````````
`````````````````````#{h}: s/.--`.-/:#{r} ``#{a}..#{s}```#{v}            .#{h}soosyhmNho#{v}.#{r}```#{a}./#{r}```````#{a}.//:#{r}```````````````````
`````````````````````#{h}+ ..++:++/-#{a}./#{r}``#{s}-.-::-`#{v}          .#{h}ddddhyos+:#{v}.#{r}```#{a}./#{r} ```#{a}.-:-#{r}``#{a}-/.#{r}`````````````````
`````````````````````#{h}o-/so/s+o/#{r}```#{s}----/+#{v}::::-..```    -:::::::::.#{r}```#{a}./#{r} `#{a}.::.#{r}``````#{a}::#{r}````````````````
````````````````````````````````````````````````````````````````````````````````````````````````````
```````````````````````````````````````````````#{Shell.get_reset}twilidoc#{r}`````````````````````````````````````````````
``````````````````````````````````````#{Shell.get_reset}Let's get this science going#{r}``````````````````````````````````
````````````````````````````````````````````````````````````````````````````````````````````````````
````````````````````````````````````````````````````````````````````````````````````````````````````\n#{Shell.get_reset}"
end

def shell_color color, &block
  code = COLORS[color]
  print "\033[#{code}m"
  block.call
  print "\033[0m"
end

def display_object object, indent = 2
  shell_color :cyan do
    if object.type.class != Symbol
      puts '[Project]'
    else
      puts "#{object.type} #{object.name}"
      di indent ; puts "Includes: #{object.inherits.inspect}"
    end
  end
  di indent ; shell_color :green do puts '[Enums]' end
  object.enums.each do |enum|
    di indent ; print "#{enum[:visibility]} \t"
    shell_color :cyan do
      print (if enum[:item].name != nil
        enum[:item].name
      else
        '[Anonymous]'
      end)
    end
    print "\t -> "
    shell_color :magenta do
      enum[:item].flags.each do |flag|
        print "#{flag[:name]} = #{flag[:value]}; "
      end
    end
    print "\n"
  end
  di indent ; shell_color :green do puts '[Types]' end
  object.typedefs.each do |typedef|
    di indent ; print "#{typedef[:visibility]} \t"
    shell_color :cyan do print typedef[:item].name end
    print ' -> '
    shell_color :magenta do print typedef[:item].type end
    print "\n"
  end
  object.objects.each do |sub_object|
    item = sub_object[:item]
    di indent
    print "#{sub_object[:visibility]} "
    display_object item, indent + 2
  end

  longest_name   = 0
  object.methods.each do |method|
    method       = method[:item]
    length       = method.name.size + method.params.size
    longest_name = length if length > longest_name
  end
  object.attributes.each do |attr|
    attr         = attr[:item]
    longest_name = attr.name.size if attr.name.size > longest_name
  end

  di indent ; shell_color :green do puts "[Method]" end
  object.methods.each do |method|
    item = method[:item]
    di indent
    shell_color :gray  do print "#{method[:visibility]} \t" end
    shell_color :cyan  do print item.name end
    shell_color :blue  do print item.params end
    (longest_name - (item.name.size + item.params.size)).times do print ' ' end
    print ' -> '
    shell_color :brown do print "#{item.type_qualifiers.inspect}" + ' ' end
    shell_color :cyan  do print item.type end
    print "\n"
  end
  di indent ; shell_color :green do puts "[Attributes]" end
  object.attributes.each do |attr|
    item = attr[:item]
    di indent
    shell_color :gray  do print "#{attr[:visibility]} \t" end
    shell_color :cyan  do print item.name end
    (longest_name - (item.name.size)).times do print ' ' end
    print ' -> '
    shell_color :brown do print "#{item.type_qualifiers.inspect}" + ' ' end
    shell_color :cyan  do print item.type end
    print "\n"
  end
end

