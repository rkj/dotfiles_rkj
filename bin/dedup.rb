#!/usr/bin/env/ruby

require 'optparse'
require 'pathname'
require 'fileutils'
require 'highline/import'
require 'digest/md5'

@opts = {
  :exact => false,
  :confirm => true,
  :real => false,
  :suffixes => %w(mp3 m4a ogg),
}
parse = OptionParser.new do |opts|
  opts.banner = "Usage $0 [options] [path]"

  opts.on("-e", "--exact", "Remove only exact duplicates") { @opts[:exact] = true }
  opts.on("-b", "--backup DIR", "Move files to backup directory") { |p| @opts[:backup] = p }
  opts.on("-p", "--preffer SUFFIX", "Suffix to prefer from duplicates") { |s| @opts[:preffer] = s } 
  opts.on("-s", "--suffixes LIST", "List of suffixes to ignore") do |p| 
    @opts[:suffixes] = p.split(',')
  end
  opts.on("-n", "--[no-]dry-run", "Do not remove anything. Default: true") { |p| @opts[:real] = !p }
  opts.on("-c", "--[no-]confirm", "Require confirmation of each deletion. Default: true") { |p| @opts[:confirm] =p }
end.parse!

@opts[:suffixes] = @opts[:suffixes].map { |s| /( [123])?\.#{s}$/ }
path = parse.pop || "."


def ext_same_md5_different(orig, file)
  return false if orig[:path][-3, 3] != file[:path][-3, 3]
  return true if orig[:size] != file[:size]
  m1, m2 = [orig, file].map { |f| Digest::MD5.hexdigest(File.read(f[:path])) }
  return m1 != m2
end

def remove(file)
  path = file[:path]
  basename = file[:basename]
  orig = @files[basename]
  # we want to get rid of duplicates, not originals
  if orig[:path] =~ / [123]\..{3}$/
    orig, file = file, orig 
    @files[orig[@key]] = orig
  end
  if @opts[:confirm] || File.dirname(path) != File.dirname(orig[:path]) || ext_same_md5_different(orig, file)
    puts "Original file '#{orig.inspect}"
    x = ask("Remove #{file.inspect} ? [y/N]\n") { |q| q.validate = /^[ynYN]$/ }
    return if x.downcase != "y"
  end

  return unless @opts[:real]
  if dir = @opts[:backup]
    file_dir = File.dirname(path.sub(@full_path, ""))
    full_dir = File.join(dir, file_dir)
    FileUtils.mkdir_p(full_dir)
    puts "Moving #{file[:path]} into #{full_dir}"
    FileUtils.mv(file[:path], full_dir)
  else
    puts "Removing: #{file[:path]}"
    FileUtils.rm(file[:path])
  end
end

#p @opts

def make_desc(full_path)
  basename = File.basename(full_path)
  @opts[:suffixes].each do |s|
    basename.gsub!(s, '')
  end
  {
    :path => full_path,
    :basename => basename,
    :size => File.size(full_path),
    #:md5 => Digest::MD5.hexdigest(File.read(full_path))
  }
end

@full_path = Pathname.new(path).expand_path
@files = {}
@key = :basename
Dir[@full_path.join('**/*')].each do |file|
  next if File.directory? file
  desc = make_desc(file)
  if @files.has_key? desc[@key]
    remove(desc)
  else
    @files[desc[@key]] = desc
  end
end

