#!/usr/bin/env ruby
#
require 'rubygems'
require 'capybara/dsl'
require 'capybara-webkit'
require 'ap'
require 'zlib'
require 'nokogiri'
require 'optparse'
require 'imdb'

def read_uri(url)
  include Capybara::DSL
  Capybara.current_driver = :webkit
  #Capybara.app_host = host
  page.visit(url)
  Nokogiri::HTML(page.html)
end

# cinema city
# url = 'http://www.cinema-city.pl/index.php?module=movie&action=repertoire&cid=1081'
# xpath = "//a[contains(@href, 'module=movie&id=;)]"

url = "http://www.amctheatres.com/movie-theatres/amc-mercado-20"
xpath = "//a[@class = 'movie-link']"

parse = OptionParser.new do |opts|
  opts.banner = "Usage $0 [options] [path]"

  opts.on("-u", "--url", "Url to download movies from") { |u| url = u }
  opts.on("-x", "--xpath", "XPath selector for movies") { |x| xpath = x }
end.parse!

list = read_uri(url)
titles = list.xpath(xpath).map { |a| a.content }
puts "Current titles"
ap titles
idx = 0
movies = titles.map do |title|
  print "\r#{idx+=1} / #{titles.size}\t\t"
  search = Imdb::Search.new(title).movies.sort_by { |m| - (m.release_date || "1900").match(/(\d{4})/)[1].to_i }
  #ap [title, search.size, search.map { |m| (m.release_date || "1900").match(/(\d{4})/)[1] } ]
  search.first
end
puts

def pu(h, k)
  puts "#{k}: #{h.send(k)}"
end

movies.sort_by { |h| -h.rating.to_f }.each do |m|
  pu m, :title
  puts m.rating.to_s + " " + "*" * m.rating.to_i
  pu m, :genres
  pu m, :tagline
  pu m, :director
  puts "-" * 40
end
