#!/usr/bin/env ruby

require 'yaml'
require 'aws-sdk'
require 'pp'
# require 'active_support/hash_with_indifferent_access'

f = YAML.load_file('test.yaml')

puts f

f.each do |resource_name, hash|
  puts "Creating #{resource_name}..."

  # client = hash['client']['class'].send(region: 'us-east-1')
  #  client = hash['client']['class'].send(*hash['client']['parameters'])

  c = Object.const_get(hash['client']['class'])
  client = c.new(**hash['client']['parameters'])
  # client = c.new(region: 'us-east-1')
  resp = client.send(hash['create']['method'], **hash['create']['parameters'])
  pp resp.to_h
  File.write('salam.txt', resp.to_h)
end
