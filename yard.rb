#!/usr/bin/env ruby

# https://stackoverflow.com/questions/25703352/in-a-ruby-an-irb-how-can-i-use-the-yard-documentation-gem-to-interact-with-th/25748239#25748239
require 'yard'
require 'yaml'
require 'pp'

# find gem root dir
spec = Gem::Specification.find_by_name('aws-sdk')
gem_root = File.expand_path('..', spec.gem_dir)

files = Dir.glob("#{gem_root}/*/lib/*/client.rb")
files.each do |file|
  puts "processing #{file}..."
  YARD::Registry.clear
  @registry = YARD::Registry.load([file], reparse: true)

  # auto-vivify hash
  hash = Hash.new { |h, k| h[k] = Hash.new(&h.default_proc) }

  klass = nil
  @registry.each do |object|
    klass = hash['class'] = object.path.split(/[.#]/)[0]
    object.tags.each do |tag|
      unless tag.respond_to?('pair')
        puts 'no pair defined; skipping...'
        next
      end

      method = tag.object.to_s.split('#')[1]
      parameter = tag.pair.name.start_with?(':') ? tag.pair.name[1..-1] : tag.pair.name
      hash['methods'][method]['parameters'][parameter]['types'] = tag.pair.types.select { |i| i != 'required' }
      hash['methods'][method]['parameters'][parameter]['required'] = tag.pair.types.include?('required')
    end
  end

  actions = {
    'create' => %w(put create run),
    'read' => %w(get describe head),
    'update' => %w(modify),
    'delete' => %w(delete terminate),
  }

  relations = Hash.new { |h, k| h[k] = Hash.new(&h.default_proc) }
  actions['create'].each do |verb|
    key = "#{verb}_"
    create = hash['methods'].keys.select { |i| i.start_with?(key) }
    create.each do |c|
      general_method_name = c[key.length..-1]
      pp general_method_name

      # generate all possible method names
      ac = actions.flatten(2).uniq.map { |s| s += "_#{general_method_name}" }
      ac += actions.flatten(2).uniq.map { |s| s += "_#{general_method_name}s" } # plural form is sometimes used

      # select methods that are actually in use
      filtered = hash['methods'].keys & ac

      # associate method with action
      actions.each do |k, v|
        relations[general_method_name][k] = filtered.select { |i| i.start_with?(*v) }[0]
      end
    end
  end
  pp relations

  # write out yaml spec
  class_parts = klass.split('::')
  dir = "#{__dir__}/providers/#{class_parts[0]}/#{class_parts[1]}"
  Dir.mkdir(dir) unless File.exist?(dir)
  filename_methods = "#{dir}/#{class_parts[1]}.yaml"
  filename_relations = "#{dir}/relations.yaml"

  File.write(filename_methods, hash.to_yaml)
  File.write(filename_relations, relations.to_yaml)
end
