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

      # count how many times we've come here (for debugging)
      if hash['methods'][method]['parameters'][parameter].key?('count')
        hash['methods'][method]['parameters'][parameter]['count'] += 1
      else
        hash['methods'][method]['parameters'][parameter]['count'] = 1
      end
    end
  end

  # write out yaml spec
  class_parts = klass.split('::')
  filename = "#{__dir__}/providers/#{class_parts[0]}/#{class_parts[1]}.yaml"
  File.write(filename, hash.to_yaml)
end
