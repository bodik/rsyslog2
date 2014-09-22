#!/usr/bin/ruby

require 'github/markup'

unless ARGV[0]
  puts "Usage: render.rb file"
  exit 1
end

STDOUT.write(GitHub::Markup.render(ARGV[0], File.read(ARGV[0])))
