#!/usr/bin/env ruby

require 'yaml'
require 'aws-sdk'
require 'pp'
require 'json'
require 'solve'

def execute(resource_name, hash, dependencies)
  puts "Creating #{resource_name}..."

  # check if resource already created
  if File.exist?("states/#{resource_name}.json")
    hash1 = JSON.parse(File.read("states/#{resource_name}.json"))['params']

    if hash == hash1
      puts 'Resource already exists.'
      return
    end
  end

  hash = JSON.parse(hash.to_json, symbolize_names: true) # to turn hash into symbols recursively

  r_type, r_name = resource_name.split('.')
  provider, mod, *resource = r_type.split('_')
  resource *= '_' # same as join!() if it existed
  pp provider
  pp mod
  pp resource

  # load methods and relations files
  filename = Dir.glob("#{__dir__}/providers/#{provider}/#{mod}/#{mod}.yaml", File::FNM_CASEFOLD).first
  mod_methods = YAML.load_file(filename)
  filename = Dir.glob("#{__dir__}/providers/#{provider}/#{mod}/relations.yaml", File::FNM_CASEFOLD).first
  mod_relations = YAML.load_file(filename)

  # load the class and send off the call
  c = Object.const_get(mod_methods['class'])
  client = c.new(region: 'us-east-1')
  pp "Passing following args to #{provider}/#{mod}/#{mod_relations[resource]['create']}"
  pp hash

  resp = client.send(mod_relations[resource]['create'], hash)

  # write state
  Dir.exist?('states') || Dir.mkdir('states')
  File.write("states/#{resource_name}.json", JSON.pretty_generate('params' => hash, 'response' => resp.to_h, 'depends_on' => dependencies))
  exit
end

f = YAML.load_file('test.yaml')

resources = {}
graph = Solve::Graph.new

# populate graph
f.each do |resource_name, hash|
  puts "Graphing #{resource_name}..."

  graph.artifact(resource_name, '1.0.0')
  deps = hash.to_s.scan(/\$\{(.*?)\}/)
  next if deps.empty?
  puts 'depends on: ' + deps.uniq.to_s

  deps.uniq.each do |dep|
    graph.artifact(resource_name, '1.0.0').depends(dep[0].split('.')[0...-1].join('.'))
  end
end
pp graph

f.keys.each do |resource_name|
  puts "Evaluating #{resource_name}..."

  deptree = Solve.it!(graph, [[resource_name]], sorted: true)
  deptree.each do |resource, _version|
    puts resource
    next if resources.key?(resource)
    puts "Executing #{resource}..."
    execute(resource, f[resource], deptree.map { |col| col[0] }[0...-1])
    resources[resource] = true
  end
end
