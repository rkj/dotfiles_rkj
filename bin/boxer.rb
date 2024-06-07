#!/usr/bin/env ruby

require 'nokogiri'

path = ARGV[0]
unless File.exists? path
  puts "Usage: #{$0} Game/Game Info.plist"
  exit 1
end
if File.directory? path
  path = File.join(path, "Game Info.plist")
end
gamedir = File.dirname(path)
conf = Nokogiri.XML(File.open(path))
key, value = nil
@dict = {}
conf.xpath("//dict").children.each do |node|
  next unless node.class == Nokogiri::XML::Element
  next key = node.content if node.name == "key"
  @dict[key] = node.content
end
binpath = @dict['BXDefaultProgramPath'] ||
  @dict['BXLauncherPath'] ||
  raise("Default program not found #{@dict}")
#dir, binary = File.split(path)
confpath = File.join(gamedir, "DOSBox Preferences.conf")
fulldir = File.join(gamedir, binpath)
cmd = "dosbox '#{fulldir}' -conf '#{confpath}' -exit"
puts cmd
system cmd
