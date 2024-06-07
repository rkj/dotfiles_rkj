#!/usr/bin/env ruby
# Based on:
# https://wiki.archlinux.org/index.php/Full_System_Backup_with_rsync
# http://www.mikerubel.org/computers/rsync_snapshots/

require 'rubygems'
require 'trollop'
require 'time'

VER = "1.0.0"

@opts = Trollop::options do
  version "Backup.rb v#{VER} by Roman Kamyk"
  banner <<-EOS
Usage:
       #{$0}.rb [options] DESTINATION
where [options] are:
EOS

  opt :src, "Source directory", :default => "/"
  opt :dest, "Destination directory", :type => :string
  opt :params, "rsync params", :default => "-aAX --delete"
  opt :exclude, "Directories to exclude", :default => "/dev,/proc,/sys,/tmp,/run,/mnt,/media,lost+found/,/home/*/.gvfs"
  opt :more_exclude, "Other dirs to exclude", :default => ""
  opt :include, "Directories to include", :default => ""
  opt :cleanup, "Remove old directories", :default => false
  opt :keep, "Number of backups to keep", :default => 7
  opt :dry_run, "Do not invoke any commands", :default => true
  opt :verbose, "Be verbose", :default => false
end

def backup
  @opts[:dest] = ARGV.shift if ARGV.size > 0
  Trollop::die :dest, "must be provided" if @opts[:dest].nil? || @opts[:dest].empty?

  if @opts[:dest].nil? || @opts[:dest].empty?
    puts "Must specifiy destination"
    puts op
    exit 1
  end
  @start = Time.now
  excludes = @opts[:exclude]
  excludes += "," + @opts[:more_exclude] unless @opts[:more_exclude].empty?
  excludes = excludes .split(',').sort.map { |e| "--exclude=#{e}" }.join " "
  includes = @opts[:include].split(',').sort.map { |e| "--include=#{e}" }.join " "
  link = "--link-dest=#{@opts[:dest]}/" if File.exists? @opts[:dest]
  dest = @opts[:dest] + Time.now.strftime(".%Y-%m-%d")
  cmd = "rsync #{@opts[:params]} #{@opts[:verbose] ? "-v":""} #{@opts[:dry_run] ? "-n":""} #{@opts[:src]} #{dest} #{link} #{excludes} #{includes}"
  puts "Excecuting: #{cmd}"
  ret = system(cmd) unless @opts[:dry_run]
  exit 0 if @opts[:dry_run]
  unless ret
    puts "Rsync failed."
    exit 2
  end
  @finish = Time.now
  system("ln -nfs #{dest} #{@opts[:dest]}")
  system %{touch #{@opts[:dest]}/"Backup from #{@start.strftime("%Y-%m-%d %H:%M:%S")}"}
  puts "total time: #{@finish - @start}"
end

def cleanup
  current = `ls -d #{@opts[:dest]}.*`.map { |e| e.strip }.sort
  old = current[0..-@opts[:keep]-1]
  cmd = "rm -rf #{old.join(" ")}"
  puts "Executing #{cmd}"
  ret = system(cmd) unless @opts[:dry_run]
end

if @opts[:cleanup]
  cleanup
end
backup
