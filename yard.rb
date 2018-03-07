# https://stackoverflow.com/questions/25703352/in-a-ruby-an-irb-how-can-i-use-the-yard-documentation-gem-to-interact-with-th/25748239#25748239
require 'yard'
require 'yaml'
require 'pp'

# auto-vivify hash
hash = Hash.new { |h, k| h[k] = Hash.new(&h.default_proc) }

@registry = YARD::Registry.load(['/Users/aabdeldayem12/Projects/coding/k8s-comet/vendor/bundle/ruby/2.4.0/gems/aws-sdk-s3-1.8.0/lib/aws-sdk-s3/client.rb'])

@registry.each do |object|
  pp object
  puts object.file
  object.tags.each do |tag|
    pp tag.object.to_s
    pp tag

    unless tag.respond_to?('pair')
      puts 'no pair defined; skipping...'
      next
    end

    klass, method = tag.object.to_s.split('#')
    pp klass
    pp method

    parameter = tag.pair.name.start_with?(':') ? tag.pair.name[1..-1] : tag.pair.name
    hash[klass][method]['parameters'][parameter]['types'] = tag.pair.types.select { |i| i != 'required' }
    hash[klass][method]['parameters'][parameter]['required'] = tag.pair.types.include?('required')
    puts 'salam'
  end
end

pp hash
File.write('S3.yaml', hash.to_yaml)
