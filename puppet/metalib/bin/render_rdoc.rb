require 'github/markup'
puts GitHub::Markup.render("file.rdoc", File.read(ARGV[0]))
