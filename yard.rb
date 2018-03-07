# https://stackoverflow.com/questions/25703352/in-a-ruby-an-irb-how-can-i-use-the-yard-documentation-gem-to-interact-with-th/25748239#25748239
require 'yard'
require 'yaml'
require 'pp'

hash = Hash.new { |h, k| h[k] = Hash.new(&h.default_proc) }
# YARD::Registry.load!

# @registry = YARD::Registry.load!()
@registry = YARD::Registry.load(['/Users/aabdeldayem12/Projects/coding/k8s-comet/vendor/bundle/ruby/2.4.0/gems/aws-sdk-s3-1.8.0/lib/aws-sdk-s3/client.rb'])

@registry.each do |object|
  pp object
  puts object.file
  # exit
  object.tags.each do |tag|
    pp tag.object.to_s
    pp tag

    unless tag.respond_to?('pair')
      #      if tag.respond_to?('pair') or tag.respond_to?('types')
      puts 'no pair defined; skipping...'
      next
    end
    klass, method = tag.object.to_s.split('#')
    pp klass
    pp method
    # hash[klass] = {} unless hash.key?(klass)
    # hash[klass][method]  = {} unless hash[klass].key?(method)
    parameter = tag.pair.name.start_with?(':') ? tag.pair.name[1..-1] : tag.pair.name
    hash[klass][method]['parameters'][parameter]['types'] = tag.pair.types.select { |i| i != 'required' }
    hash[klass][method]['parameters'][parameter]['required'] = tag.pair.types.include?('required')
    puts 'salam'
  end

  #   object.tags.each do |tag|
  #     pp tag
  #     exit
  #     puts tag.name
  #     puts tag.object
  #     puts tag.tag_name
  #     # puts tag.text
  #     puts tag.types
  #     puts tag.pair if tag.respond_to?('YARD::Tags::OptionTag')
  #   end
  # puts object.instance_variables
  puts object.docstring
  case object.type
  when :constant
    # scripts.push(object.file)
    # generate_constant(object)
  when :class, :module
    puts object.methods

    #    exit
    # scripts.push(object.file)
    # generate_class(object)
    # TODO: is this needed?
    # object.constants.each do |c|
    #  generate_constant(c)
    # end
  when :method
    # scripts.push(object.file)
    # generate_method(object)
  else
    $stderr.puts "What is an #{object.type}? Ignored!"
  end
end

pp hash
File.write('S3.yaml', hash.to_yaml)

exit
# puts YARD::Registry.all
puts YARD::Registry.all.count
# puts YARD::Registry.all(:method).map(&:path)
# puts YARD::Registry.all(:method).map(&:docstring)
puts YARD::Registry.all(:method).each do |d|
  puts d.methods
  puts d.docstring
  exit
end

# https://github.com/lsegal/yard/issues/1036

exit

require 'yard'

project_path = File.expand_path(File.join(__dir__, '..', 'SUbD'))
pattern = File.join(project_path, 'Ruby', '**/*.rb')
files = Dir.glob(pattern).to_a

puts "#{files.size} files"
files = ['/Users/aabdeldayem12/Projects/coding/k8s-comet/vendor/bundle/ruby/2.4.0/gems/aws-sdk-s3-1.8.0/client.rb']
puts 'salam'
puts files
YARD::Registry.load(files)

puts YARD::Registry.all.count
puts YARD::Registry.all(:method).map(&:path)
