# https://stackoverflow.com/questions/25703352/in-a-ruby-an-irb-how-can-i-use-the-yard-documentation-gem-to-interact-with-th/25748239#25748239
require 'yard'
require 'yaml'
require 'pp'

files = [
  __dir__ + '/vendor/bundle/ruby/2.4.0/gems/aws-sdk-s3-1.8.2/lib/aws-sdk-s3/client.rb',
  __dir__ + '/vendor/bundle/ruby/2.4.0/gems/aws-sdk-ec2-1.29.0/lib/aws-sdk-ec2/client.rb',
  __dir__ + '/vendor/bundle/ruby/2.4.0/gems/aws-sdk-ecs-1.9.0/lib/aws-sdk-ecs/client.rb',
]

paths = []
files.each do |file|
  puts "processing #{file}..."
  YARD::Registry.clear
  @registry = YARD::Registry.load([file], reparse: true)

  # auto-vivify hash
  hash = Hash.new { |h, k| h[k] = Hash.new(&h.default_proc) }

  @registry.each do |object|
    #     pp object
    #     puts object.methods
    #     puts object.to_yaml
    #     puts object.path
    #     path = object.path
    paths << object.path

    object.tags.each do |tag|
      # pp tag.object.to_s
      # pp tag

      unless tag.respond_to?('pair')
        puts 'no pair defined; skipping...'
        next
      end

      klass, method = tag.object.to_s.split('#')
      pp klass
      pp method

      parameter = tag.pair.name.start_with?(':') ? tag.pair.name[1..-1] : tag.pair.name
      hash['methods'][method]['parameters'][parameter]['types'] = tag.pair.types.select { |i| i != 'required' }
      hash['methods'][method]['parameters'][parameter]['required'] = tag.pair.types.include?('required')

      if hash['methods'][method]['parameters'][parameter].key?('count')
        hash['methods'][method]['parameters'][parameter]['count'] += 1
      else
        hash['methods'][method]['parameters'][parameter]['count'] = 1

      end
      # puts hash; exit
      puts 'salam'
    end

    hash['class'] = object.path.split(/[.#]/)[0]

    puts paths
    class_parts = object.path.split('::')
    filename = "#{__dir__}/providers/#{class_parts[0]}/#{class_parts[1]}.yaml"

    File.write(filename, hash.to_yaml)
  end
  #   exit
  #   # pp hash
  #   hash.each do |klass, body|
  #     puts "Writing class #{klass}"
  #     class_parts = klass.split('::')
  #     filename = "#{__dir__}/providers/#{class_parts[0]}/#{class_parts[1]}.yaml"
  #
  #     body1 = {}
  #     body1['class'] = klass
  #     body1['methods'] = body
  #
  #     File.write(filename, body1.to_yaml)
  #   end
  # =e
end
