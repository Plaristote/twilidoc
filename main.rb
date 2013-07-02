#!/usr/bin/ruby
@active_log = false
def require_local name
 path  = File.expand_path (File.dirname __FILE__)
 path += "/#{name}.rb"
 require path
end

require       'optparse'

options = {
    output: 'doc',
    input:  'twilidoc.yml'
  }

OptionParser.new do |opts|
  opts.banner = "usage: #{ARGV[0]} [options]"
  opts.on '-o', '--output PATH', 'Set an output'     do |v| options[:output] = v end
  opts.on '-i', '--input',  'Set input project file' do |v| options[:input]  = v end
end.parse!

require       'yaml'
CONF = YAML.load (File.open options[:input])
require       'json'
require_local 'sexydoc'
require_local 'preprocessor'
require_local 'cppparser'

headers      = []
descriptors  = []

CONF['includes'].each do |path|
  dot_h        = Dir.glob "#{path}/**/*.h"
  dot_hpp      = Dir.glob "#{path}/**/*.hpp"
  dot_yml      = Dir.glob "#{path}/**/*.yml"
  headers     += dot_h + dot_hpp
  descriptors += dot_yml
end

preprocessor = CppParser::Preprocessor.new
preprocessor.inc_pathes = CONF['includes']

project_desc = {}

print "Running preprocessor..."
headers.each     do |header|
  preprocessor.parse header
end
descriptors.each do |descriptor|
  yml        = YAML.load (File.open descriptor)
  project_desc.merge! yml
end
puts " [Done]"

line_length  = 0

filemap      = preprocessor.filemap
sample       = preprocessor.source

project      = SexyDoc::Project.new
project.name = CONF['name']
project.desc = CONF['description']
project.doc  = project_desc

namespaces      = []
file_arch       = []
visibility_arch = []
func_scopes     = []
def get_file_containing declared_at, filemap
  file = nil
  filemap.each do |block|
    file = block[:filename] ; break if block[:beg] <= declared_at[0] and block[:end] >= declared_at[1]
  end
  file
end

def get_namespace declared_at, namespaces
  namespace = nil
  namespaces.each do |block|
    namespace = block[:name] if block[:beg] <= declared_at[0] and block[:end] >= declared_at[1]
  end
  namespace
end

def get_visibility declared_at, visibility_arch
  visibility = 'unknown'
  visibility_arch.each do |block|
    if block[:beg] <= declared_at and block[:end] >= declared_at
      visibility = block[:visibility]
    end
  end
  visibility
end

def is_in_func? declared_at, func_scopes
  func_scopes.each do |block|
    return true if block[:beg] <= declared_at and block[:end] >= declared_at
  end
  false
end

##
## Here we duplicate the code.
## 'sample' will be the original code.
## 'code'   will be the code with wiped out commentaries and string
##
#require 'ruby-progressbar'
class ProgressBarStub
  def increment
  end
  def finish
  end
end

i    = 0
code = sample.dup
#bar  = ProgressBar.create title: 'Wiping out commentaries and strings', total: (code.size + 1)
bar  = ProgressBarStub.new

n_parts   = code.size / 20000
part_size = code.size / n_parts
parts     = []
n_parts.times do
  parts << (code[part_size * parts.size...part_size])
end

puts '-> Wiping out commentaires and string'
thread_pool = []
parts.each do |part|
  thread = Thread.new do
    li = 0
    while li < part.size
      p = CppParser.handle_skip part, li
      if p != li
        ii = li
        while ii <= p
          part[ii] = '#'
          ii += 1
        end
        ((p - 1) / n_parts).times { bar.increment }
        li = p
      end
      bar.increment
      li += 1
    end
  end
  thread_pool << thread
end

thread_pool.each do |thread|
  thread.join
end
bar.finish

code = parts.join
puts '--> Done'

code.scan /namespace\s+([a-zA-Z0-9_]+)\s+{/m do
  namespace = $1
  beg       = ($~.offset 1)[0]
  _end      = ($~.offset 1)[1]

  code_sample = code[_end..code.size]
  inline_code = CppParser.get_filtered_block code_sample  
  
  _end        = beg + inline_code.size
  
  father    = get_namespace [ beg, _end ], namespaces
  namespace = "#{father}::#{namespace}" unless father.nil?
  namespaces << { :beg => beg, :end => _end, name: namespace }
end

code.scan /(class|struct|union)\s+([a-zA-Z0-9_]+)\s+(:([^{]*))?{/ do
  decl_type    = $1
  class_name   = $2
  symbol       = class_name
  inheritences = $4
  inline_code  = ''

  print "\r"
  line_length.times do print ' ' end
  line        = "PARSING CLASS #{class_name}"
  line_length = line.size
  print "\r#{line}"

  inherits = unless inheritences.nil?
    inheritences = inheritences.split ','
    to_ret = []
    inheritences.each do |i|
      elems = i.split ' '
      to_ret << { visibility: elems[0].to_sym, class: elems[1] }
    end
    to_ret
  else
    []
  end

  offset_begin = if $4.nil? then $~.offset 2 else $~.offset 4 end[1]
  code_sample  = sample[offset_begin..sample.size]
  #inline_code  = CppParser.get_block code_sample
  inline_code  = CppParser.get_filtered_block code_sample

  # Since this procedure is supposed to find class in the right order,
  # we should not have to check for which is the deepest file_arch match:
  # the last one should be the deepest
  file_arch.each do |arch|
    if arch[:beg] < offset_begin and arch[:end] > offset_begin + inline_code.size
      symbol = "#{arch[:symbol]}::#{class_name}"
    end
  end
  namespace = get_namespace [ offset_begin, offset_begin + inline_code.size ], namespaces
  symbol = "#{namespace}::#{symbol}" unless namespace.nil?
  file_arch << { beg: offset_begin, end: offset_begin + inline_code.size, symbol: symbol }
  ##
  ## Find containing file
  ##
  file = get_file_containing [ offset_begin, offset_begin + inline_code.size ], filemap

  ##
  ## Visibility (public/protected/private) map generation
  ##
  visibility_it      = offset_begin
  visibility_current = if decl_type == 'class' then 'private' else 'public' end
  i                  = 0
  while i < inline_code.size
    tocheck = [ 'public', 'protected', 'private' ]
    tocheck.each do |visib|
      if inline_code[i..i + visib.size] == visib + ':'
	visibility_arch << { beg: visibility_it, end: offset_begin + i, visibility: visibility_current }
	visibility_current = visib
	visibility_it      = offset_begin + i + visib.size
	i                 += visib.size
	break
      end
    end
    i += 1
  end
  visibility_arch << { beg: visibility_it, end: offset_begin + inline_code.size, visibility: visibility_current }

  #puts "Decl type    #{decl_type}"
  #puts "Class name   #{symbol}"
  #puts "Inherits:    #{inherits.inspect}"
  #puts code

  type             = SexyDoc::Type.new project
  type.name        = symbol
  type.declared_in = file
  type.declared_as = decl_type
  type.ancestors   = inherits

  project.types << type
end
puts ''

##
## Fetch typedefs
##
code.scan /typedef\s+([^;]+)\s+([^;]+)\s*;/ do
  belongs_to  = nil
  file_arch.each do |arch|
    if arch[:beg] < ($~.offset 1)[0] and arch[:end] > ($~.offset 2)[0]
      belongs_to = arch[:symbol]
    end
  end

  belongs_to = project.find_type belongs_to unless belongs_to.nil?
  namespaces = unless belongs_to.nil? then belongs_to.namespaces project else [] end

  name         = $2
  typename     = $1
  type         = project.find_type typename, namespaces
  name         = if belongs_to.nil? then name else "#{belongs_to.name}::#{name}" end
  typedef      = SexyDoc::Typedef.new typename, type
  typedef.name = name

  project.types << typedef
end

##
## Fetch operator overloads
##
overloads = [
    'operator=',
    'operator==',
    'operator!=',
    'operator<',
    'operator>',
    'operator++',
    'operator--',
    'operator*',
    'operator+',
    'operator-',
    'operator[]',
    'operator()',
    'operator->',
  ]
overloads = (overloads.map { |overload| Regexp.quote overload }).join '|'

##
## Fetch functions
##
code.scan /((([a-z0-9_]+::)*[a-z0-9_&*]+\s+)+)([a-z0-9_,\s]+|#{overloads})\s*(\([^)]*\))/i do
  return_type = $1
  name        = $4

  next if return_type.strip == 'new' 

  # In some cases the regex fails to find the function's name. In this case it
  # is stored as a return qualifier. Either fix the regex or keep this block:
  if name == ' '
    words       = return_type.split ' '
    name        = words.last
    return_type = words[0...words.size - 1].join ' '
  end

  print "\r"
  line_length.times do print ' ' end
  line        = "PARSING METHODS #{name} -> #{return_type.strip!}"

  line_length = line.size
  print "\r#{line}"

  method      = SexyDoc::Function.new project
  method.name = name

  end_offset  =  $~.offset 5
  i           = end_offset[1]
  while i < code.size
    method.attrs |= SexyDoc::ATTR_CONST if code[i..(i + 'const'.size - 1)] == 'const'
    break if code[i] == ';'
    if code[i] == '{'
      code_begin  = i
      method.code = CppParser.get_block sample[i..sample.size]
      func_scopes << { beg: i, end: i + method.code.size, method: method }
      break
    end
    i += 1
  end

  params_offset = $~.offset 5
  parameters    = sample[params_offset[0]...params_offset[1]]
  parameters    = parameters.split ','
  parameters.each {|p| p.strip! }

  method.parameters = parameters

  return_type_spec = []
  type_specs = return_type.split ' '
  type_specs.each do |type_spec|
    case type_spec
    when 'inline'
      method.attrs |= SexyDoc::ATTR_INLINE
    when 'static'
      method.attrs |= SexyDoc::ATTR_STATIC
    when 'virtual'
      method.attrs |= SexyDoc::ATTR_VIRTUAL
    else
      return_type_spec << type_spec
    end
  end

  return_type = CppParser.attribute_from_type type_specs
  next if return_type.nil? # Is not a real function call

  belongs_to  = nil
  file_arch.each do |arch|
    if arch[:beg] < ($~.offset 1)[0] and arch[:end] >= ($~.offset 1)[0]
      belongs_to = arch[:symbol]
    end
  end

  method.visibility = get_visibility ($~.offset 1)[0], visibility_arch

  type         = nil
  namespaces   = []
  unless belongs_to.nil?
    type       = project.find_type belongs_to
    namespaces = (type.namespaces project) unless type.nil?
  end
  method.klass = type
  type.functions << method unless type.nil?

  typename    = return_type.type
  method.return_type[:attrs] = return_type.attrs
  method.return_type[:type]  = project.find_type return_type.type, namespaces
  method.return_type[:type]  = typename if method.return_type[:type].nil?

  return_type_spec.each do |type_spec|
    case type_spec
    when 'const'
      method.return_type[:attrs] |= SexyDoc::ATTR_CONST
    when 'unsigned'
      method.return_type[:attrs] |= SexyDoc::ATTR_UNSIGNED
    else
      type      = type_spec
      last_char = type[type.size - 1]
      if last_char == '*' or last_char == '&'
        type    = type[0...(type.size - 1)]
        if last_char == '*'
          method.return_type[:attrs] |= SexyDoc::ATTR_PTR
        elsif last_char == '&'
          method.return_type[:attrs] |= SexyDoc::ATTR_REF
        end
      end
      type = project.find_type type, namespaces
      method.return_type[:type] = type unless type.nil?
    end
  end
end
puts ''

##
## Fetch attributes
##
code.scan /(([a-z0-9_&*]+(::[a-z0-9_&*]+)*\s+)+)([a-z0-9_,\s&*]+)\s*;/i do
  beg        = ($~.offset 1)[0]
  fin        = ($~.offset 4)[1]
  belongs_to = nil

  next if is_in_func? beg, func_scopes

  file_arch.each do |arch|
    if arch[:beg] <= beg and arch[:end] > beg
      belongs_to = arch[:symbol]
    end
  end

  type   = nil
  unless belongs_to.nil?
    type = project.find_type belongs_to
  end

  attrs = $4.split ','
  attrs.each_with_index do |attr, i|
    attribute         = CppParser.attribute_from_type $1.split ' ', i
    next if attribute.nil? # Not an actual attribute
    attribute.name    = attr.strip
    attribute.project = project
    if attribute.name[0] == '*' or attribute.name[0] == '&'
      if attribute.name[0] == '*'
        attribute.attrs |= SexyDoc::ATTR_PTR
      elsif attribute.name[0] == '&'
        attribute.attrs |= SexyDoc::ATTR_REF
      end
      attribute.name = attribute.name[1..attribute.name.size]
    end
    attribute.klass      = type
    attribute.visibility = get_visibility beg, visibility_arch
    type.attributes << attribute unless type.nil?
  end
end

require 'erb'

class String
  def escape_quotes
    gsub '"', '&quot;'
  end
end

# Generating files from ERB

o_prefix = options[:output]
i_prefix = File.expand_path (File.dirname __FILE__)

js_template     = ERB.new (File.read "#{i_prefix}/project.js.erb")

typedefs = project.typedefs
str = "typedefs: ["
i   = 0
while i < typedefs.count
  str += "{ name: \"#{typedefs[i].name}\", to: \"#{typedefs[i].typedef_to}\" }"
  str += ",\n" if i < typedefs.count - 1
  i += 1
end
str += ']'
typedefs_json = str
puts "Done Generating Typedef JS"

File.open "#{o_prefix}/project.js", 'w' do |f|
  json = js_template.result binding
  json += ",\n  #{typedefs_json}\n};"
  f.write json
end
