# fork from: https://github.com/singpolyma/FuseFS/blob/master/sample/openurifs.rb
# prerequisite: libfusefs-ruby

require 'fusefs'
require 'open-uri'

class OpenUriFS < FuseFS::FuseDir
  def initialize
    @proto = ARGV.shift || "http"
  end

  def directory?(path)
    return path.rindex("/") == 0
  end

  def file?(path)
    return path.rindex("/") > 0
  end

  def read_file(path)
    #p ['read_file', path]
    uri = "#{@proto}:/#{path}"
    str = open(uri)
    #p ['opened', str]
    data = str.read
    #p ['data', data]
    data
  end
end

if File.basename($0) == File.basename(__FILE__)
  if ARGV.size < 1
    puts "Usage: #{$0} <directory> [protocol (http/https)]"
    exit
  end
  dirname = ARGV.shift
  unless File.directory?(dirname)
    puts "Usage: #{dirname} is not a directory."
    exit
  end
  root = OpenUriFS.new
  # Set the root FuseFS
  FuseFS.set_root(root)
  FuseFS.mount_under(dirname)
  FuseFS.run # This doesn't return until we're unmounted.
end
