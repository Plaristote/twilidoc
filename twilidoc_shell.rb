def di indent
  indent.times { print ' ' }
end

COLORS = { black: 30, red: 31, green: 32, brown: 33, blue: 34, magenta: 35, cyan: 36, gray: 37 }

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

