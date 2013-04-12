#!/usr/bin/ruby

def require_local name
 path  = File.expand_path (File.dirname __FILE__)
 path += "/#{name}.rb"
 require path
end

require       'yaml'
CONF = YAML.load (File.open 'twilidoc.yml')
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

headers.each     do |header|
  preprocessor.parse header
end
descriptors.each do |descriptor|
  yml        = YAML.load (File.open descriptor)
  project_desc.merge! yml
end

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
    namespace = block.name if block[:beg] <= declared_at[0] and block[:end] >= declared_at[1]
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
require 'ruby-progressbar'

i    = 0
code = sample.dup
bar  = ProgressBar.create title: 'Wiping out commentaries and strings', total: (code.size + 1)
while i < code.size
  p = CppParser.handle_skip code, i
  if p != i
    ii = i
    while ii <= p
      code[ii] = '#'
      ii += 1
    end
    (p - i).times { bar.increment }
    i = p
  end
  bar.increment
  i += 1
end
bar.finish

code.scan /namespace\s+([a-z0-9_]+)\s+{/im do
  namespace = $1
  beg       = ($~.offset 1)[0]
  _end      = ($~.offset 1)[1]
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

  10.times do print ' ' end
  print "\rPARSING CLASS #{class_name}"

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
  inline_code  = CppParser.get_block code_sample

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
  i                  = offset_begin
  while i < (offset_begin + inline_code.size)
    tocheck = [ 'public', 'protected', 'private' ]
    tocheck.each do |visib|
      if code[i..i + visib.size] == visib + ':'
	visibility_arch << { beg: visibility_it, end: i, visibility: visibility_current }
	visibility_current = visib
	visibility_it      = i + visib.size
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
#exit 0

##
## Fetch typedefs
##
code.scan /typedef\s+([^;]+)\s+([^;]+)\s*;/ do
  puts "Typedef matching: "
  
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

  puts "Defined typedef '#{typedef.name}' pointing to #{if type.nil? then typename else type.name end}"

  project.types << typedef
end

##
## Fetch functions
##
code.scan /((([a-z0-9_]+::)*[a-z0-9_&*]+\s+)+)([a-z0-9_,\s]+)\s*(\([^)]*\))/i do
  puts "matching a function/method"
  return_type = $1
  name        = $4
  puts "#{return_type} #{name}"
 
  next if return_type.strip == 'new' 

  puts return_type

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

  parameters = $5[1...($5.size - 1)]
  parameters = parameters.split ','
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
#   if arch[:beg] < ($~.offset 1)[0] and arch[:end] > ($~.offset 2)[0]
    if arch[:beg] < ($~.offset 1)[0] and arch[:end] >= ($~.offset 1)[0]
      belongs_to = arch[:symbol]
    end
  end

  method.visibility = get_visibility ($~.offset 1)[0], visibility_arch

  puts "Searching type for #{method.visibility} method #{method.name}"

  type         = nil
  namespaces   = []
  unless belongs_to.nil?
    type       = project.find_type belongs_to
    namespaces = (type.namespaces project) unless type.nil?
    puts type.name unless type.nil?
    puts namespaces.inspect
  end
  method.klass = type
  type.functions << method unless type.nil?

  typename    = return_type.type
  method.return_type[:attrs] = return_type.attrs
  puts "Return type name is #{return_type.type}"
  method.return_type[:type]  = project.find_type return_type.type, namespaces
  puts "Done return type name"
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

o_prefix = "twilidoc"
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

File.open "#{o_prefix}/js/project.js", 'w' do |f|
  json = js_template.result binding
  json += ",\n  #{typedefs_json}\n};"
  f.write json
end
