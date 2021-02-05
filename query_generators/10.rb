#!/usr/bin/env ruby

require 'date'
require 'pry'

QUERY = File.basename($0).sub('.rb', '')
MODE = ARGV[0]
SCALE = ARGV[1]
ITEM = ARGV[2].to_i

require_relative "../query_parameters/q#{QUERY}_s#{SCALE}.rb"

params = PARAMS[ITEM - 1]

date_min = Date.new(*(params[0].split('-').map{ |x| x.to_i}))
date_max = date_min << -3

substitutions = {
  '1993-11-01' => date_min.to_s,
  '1994-02-01' => date_max.to_s
}

query = File.new("sparql_examples/#{QUERY}_#{MODE}.sparql").read

substitutions.keys.each { |k| query.gsub!(k, "@#{k}") }
substitutions.each { |k,v| query.gsub!("@#{k}", v) }

puts query
