#!/usr/bin/ruby
@active_log = false
$: << (File.expand_path (File.dirname __FILE__))

require 'optparse'

options = {
    output: 'doc',
    input:  'twilidoc.yml'
  }

OptionParser.new do |opts|
  opts.banner = "usage: #{ARGV[0]} [options]"
  opts.on '-o', '--output PATH', 'Set an output'     do |v| options[:output] = v end
  opts.on '-i', '--input PATH',  'Set input project file' do |v| options[:input]  = v end
  opts.on '-s', '--source PATH', 'Use already compiled headers instead of compiling them' do |v| options[:source] = v end
  opts.on '-c', '--compile PATH', 'Output the compiled headers in a file' do |v| options[:compile_output] = v end
end.parse!

require 'yaml'
CONF = YAML.load (File.open options[:input])
require 'json'
require 'twilidoc_string'
require 'preprocessor'
require 'parse'

headers      = []
descriptors  = []

CONF['includes'].each do |path|
  dot_h        = Dir.glob "#{path}/**/*.h"
  dot_hpp      = Dir.glob "#{path}/**/*.hpp"
  dot_yml      = Dir.glob "#{path}/**/*.yml"
  headers     += dot_h + dot_hpp
  descriptors += dot_yml
end

print "Loading documentation..."
project_desc = {}

descriptors.each do |descriptor|
  yml        = YAML.load (File.open descriptor)
  project_desc.merge! yml
end
puts " [Done]"

sample = if options[:source].nil?

  preprocessor = CppParser::Preprocessor.new
  preprocessor.inc_pathes = CONF['includes']

  print "Running preprocessor..."
  headers.each     do |header|
    preprocessor.parse header
  end
  puts " [Done]"

  line_length  = 0

  filemap      = preprocessor.filemap
  sample       = preprocessor.source

  File.open options[:compile_output], 'w' do |f|
    f.write sample
  end unless options[:compile_output].nil?

  sample
else
  File.read options[:source]
end

print "Running cpp probe..."
global_scope = ClassParser::Object.new
fuente       = ClassParser.new sample
fuente.probe global_scope
puts " [Done]"

json = String.new

def document_objects global_scope, doc
  doc.each do |key,value|
    puts "Documentation for #{key}"
    object     = global_scope.solve_type key

    if object.nil?
      $stderr.print "Cannot solve type #{key}\n"
      next
    end

    object.doc = { overview: value['overview'], detail: value['detail'] }

    i    = 0
    while i < object.methods.size and i < value['methods'].size
      object.methods[i][:item].doc = value['methods'][i]
      i += 1
    end unless value['methods'].nil?

    i    = 0
    while i < object.attributes.size and i < value['attributes'].size
      object.attributes[i][:item].doc = value['attributes'][i]
      i += 1
    end unless value['attributes'].nil?

    puts "->  #{object.inspect}"
    puts "->  #{value.inspect}"
    puts ''
  end
end

ATTR_PTR      = 1
ATTR_REF      = 2
ATTR_CONST    = 4
ATTR_UNSIGNED = 8
ATTR_STATIC   = 16
ATTR_INLINE   = 32
ATTR_VIRTUAL  = 64
ATTR_TYPEDEF  = 128

def flags2num flags
  matches = {
    pointer:   1,
    reference: 2,
    const:     4,
    unsigned:  8,
    static:    16,
    inline:    32,
    virtual:   64,
  }
  num = 0
  flags.each do |value|
    num += matches[value] unless matches[value].nil?
  end
  num
end

def jsonify_object object, namespaces, json = nil
  hash = Hash.new
  if object.class == Hash
    hash[:visibility] = object[:visibility]
    object            = object[:item]
  end
  hash[:name]       = object.name
  hash[:name]       = "#{namespaces.join '::'}::#{hash[:name]}" if namespaces.size > 0
  hash[:decl]       = object.type
  hash[:file]       = ''
  hash[:namespaces] = namespaces

  hash[:constructors] = Array.new
  hash[:methods]      = Array.new
  hash[:attributes]   = Array.new
  hash[:enums]        = Array.new
  hash[:typedefs]     = Array.new
  hash[:ancestors]    = object.inherits or Array.new
  hash[:doc]          = object.doc

  object.methods.each do |method|
    hash_meth                = Hash.new
    visibility               = method[:visibility]
    method                   = method[:item]
    hash_meth[:name]         = method.name
    hash_meth[:params]       = method.params
    hash_meth[:attrs]        = flags2num method.qualifiers
    hash_meth[:return_type]  = method.type
    hash_meth[:visibility]   = visibility
    hash_meth[:return_attrs] = flags2num method.type_qualifiers
    hash_meth[:doc]          = method.doc
    hash[:methods] << hash_meth
  end

  object.attributes.each do |attribute|
    hash_attr              = Hash.new
    visibility             = attribute[:visibility]
    attribute              = attribute[:item]
    hash_attr[:name]       = attribute.name
    hash_attr[:type]       = attribute.type
    hash_attr[:attrs]      = flags2num attribute.type_qualifiers
    hash_attr[:visibility] = visibility
    hash_attr[:doc]        = attribute.doc
    hash[:attributes] << hash_attr
  end

  object.typedefs.each do |typedef|
    json[:typedefs]           = Array.new if json[:typedefs].nil?
    hash_typedef              = Hash.new
    prename                   = if object.name.nil? then '' else hash[:name] + '::' end
    hash_typedef[:name]       = prename + typedef[:item].name
    hash_typedef[:to]         = typedef[:item].type
    hash_typedef[:visibility] = typedef[:visibility]
    json[:typedefs] << hash_typedef
  end

  object.objects.each do |sub_object|
    sub_namespaces = namespaces.dup
    sub_namespaces << object.name unless object.name == nil
    json = jsonify_object sub_object, sub_namespaces, json
  end

  json[:types]  = Array.new if json[:types].nil?
  json[:types] << hash
  json
end

document_objects global_scope, project_desc

project_desc = { homepage: CONF['description'] }
project_json = { name: CONF['name'], desc: project_desc }
json         = jsonify_object global_scope, [], project_json

File.open "#{options[:output]}/project.js", 'w' do |f|
  f.write 'var project = '
  f.write json.to_json
  f.write ';'
end

