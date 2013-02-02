
class Command
  attr_accessor :config
end

require "#{File.dirname(__FILE__)}/command-helper.rb"

commands_dir = "#{File.dirname(__FILE__)}/commands"
Dir.glob("#{commands_dir}/*.rb") do |filename|
  require filename
end

