#!/usr/bin/env ruby

require 'date'
require 'pry'

QUERY = File.basename($0).sub('.rb', '')
MODE = ARGV[0]
SCALE = ARGV[1]
ITEM = ARGV[2].to_i

require_relative "../query_parameters/q#{QUERY}_s#{SCALE}.rb"

params = PARAMS[ITEM - 1]

date_min = Date.new(*(params[2].split('-').map{ |x| x.to_i}))
date_max = Date.new(date_min.year + 1, date_min.month, date_min.day)

substitutions = {
  'FOB' => params[0],
  'REG AIR' => params[1],
  '1993-01-01' => date_min.to_s,
  '1994-01-01' => date_max.to_s
}

query = File.new("sparql_examples/#{QUERY}_#{MODE}.sparql").read

substitutions.keys.each { |k| query.gsub!(k, "@#{k}") }
substitutions.each { |k,v| query.gsub!("@#{k}", v) }

puts query
