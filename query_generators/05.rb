#!/usr/bin/env ruby

require 'date'
require 'pry'

QUERY = File.basename($0).sub('.rb', '')
MODE = ARGV[0]
SCALE = ARGV[1]
ITEM = ARGV[2].to_i

require_relative "../query_parameters/q#{QUERY}_s#{SCALE}.rb"

params = PARAMS[ITEM - 1]

r_name = params[0]
date1 = Date.new(*(params[1].split('-').map{ |x| x.to_i}))
date2 = Date.new(date1.year + 1, date1.month, date1.day)

substitutions = {
  'AMERICA' => r_name,
  '1993-01-01' => date1.to_s,
  '1994-01-01' => date2.to_s
}

query = File.new("sparql_examples/#{QUERY}_#{MODE}.sparql").read

substitutions.keys.each { |k| query.gsub!(k, "@#{k}") }
substitutions.each { |k,v| query.gsub!("@#{k}", v) }

puts query
