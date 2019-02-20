#!/usr/bin/env ruby

require 'yaml'
require 'aws-sdk'
require 'pp'
require 'json'

f = YAML.load_file('test.yaml')

puts f

f.each do |resource_name, hash|
  puts "Creating #{resource_name}..."

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
  # client = c.new(**hash)
  client = c.new(region: 'us-east-1')
  pp "Passing following args to #{provider}/#{mod}/#{mod_relations[resource]['create']}"
  pp **hash.transform_keys(&:to_sym)

  resp = client.send(mod_relations[resource]['create'], **hash.transform_keys(&:to_sym))
  pp resp.to_h
  File.write('log.txt', resp.to_h, mode: 'a')
end
