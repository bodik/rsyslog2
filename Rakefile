#https://raw.githubusercontent.com/brightbox/puppet/master/Rakefile#
task :default => [:doc]

desc "Generate documentation from README.rdoc and manifests"
task :doc do
  require 'github/markup'
  require 'puppet'
  require 'puppet/util/rdoc'

  out = '<link href="puppet/metalib/style.css" rel="stylesheet"></link>'
  out += GitHub::Markup.render("README.rdoc", File.read("README.rdoc"))
  File.open("README_full.html", 'w') { |file| file.write(out) }
end

