#!/usr/bin/env ruby

require 'date'

class Date
  def self.dayname(day = self.wday)
    DAYNAMES[day]
  end

  def self.abbr_dayname(day = self.wday)
    ABBR_DAYNAMES[day]
  end
end

if __FILE__ == $0
  path = ARGV[0] || File.join(ENV['HOME'], '.workrave/historystats')
  date = nil
  stats = []
  sum = [0, 0]
  weeks = 0
  days = 0
  max = [0, 0]
  IO.readlines(path).each do |line|
    if line =~ /^D (\d+) (\d+) (\d+)/
      date = Date.new($3.to_i+1900, $2.to_i+1, $1.to_i)
      if date.wday == 1
        puts "---"
        weeks += 1
     end
    elsif line =~ /^m .*? (\d+) (\d+)\s*$/
     clicks, keystrokes = [$1.to_i, $2.to_i]
     stats[date.wday] ||= [0, 0, 0]
     stats[date.wday][0] += clicks
     stats[date.wday][1] += keystrokes
     stats[date.wday][2] += 1 if clicks > 0 || keystrokes > 0
     sum[0] += clicks
     sum[1] += keystrokes
     max[0] = [max[0], clicks].max
     max[1] = [max[1], keystrokes].max
     next if clicks == 0 && keystrokes == 0
     days += 1
     puts "#{date.strftime("%a, %Y-%m-%d")} clicks: #{clicks.to_s.rjust(5)}, keystrokes: #{keystrokes.to_s.rjust(5)}"
    end
  end
  puts "\nTotal stats for #{weeks} weeks (#{days} days of activity}):"
  stats.each_with_index do |s, idx|
    next if s[2] <= 0
    clicks = "clicks: #{s[0].to_s.rjust(10)} (#{(s[0] / s[2]).to_i.to_s.rjust(6)} / day)"
    keystrokes = "keystrokes: #{s[1].to_s.rjust(10)} (#{(s[1] / s[2]).to_i.to_s.rjust(6)} / day)"
    puts "#{Date.abbr_dayname(idx)}\t#{clicks}, #{keystrokes}"
  end
  puts "Grand total clicks: #{sum[0].to_s.rjust(10)}, keystrokes: #{sum[1].to_s.rjust(10)}"
  puts ""
  puts "One day max clicks: #{max[0].to_s.rjust(10)}, keystrokes: #{max[1].to_s.rjust(10)}"
  puts "Average day clicks: #{(sum[0]/days).to_s.rjust(10)}, keystrokes: #{(sum[1]/days).to_s.rjust(10)}"
end

