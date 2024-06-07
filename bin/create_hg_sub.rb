#!/usr/bin/env ruby

@hgsub = File.read('.hgsub') rescue ""
def add_subrepo(local_path, remote_path)
  local = File.dirname(local_path)
  return if local == '.'
  @hgsub << "#{local} = #{remote_path}\n"
end

Dir["**/.git"].each do |gitsub|
  config = File.read(File.join(gitsub, 'config')) rescue ""
  remote = config.match(/^\s*url\s*=\s*(.*)$/)[1] rescue "TODO_UNKNOWN"
  add_subrepo(gitsub, '[git]' + remote)
end

Dir["**/.hg"].each do |hgsub|
  hgrc = File.read(File.join(hgsub, 'hgrc')) rescue ""
  remote = hgrc.match(/^\s*default\s*=\s*(.*)$/)[1] rescue "TODO_UNKNOWN"
  add_subrepo(hgsub, remote)
end

Dir["**/.svn"].each do |svnsub|
  remote = "TODO_UNKNOWN"
  add_subrepo(svsub, '[svn]' + remote)
end

puts @hgsub

