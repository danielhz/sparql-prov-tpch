#!/usr/bin/env ruby

require 'date'
require 'pry'

QUERY = File.basename($0).sub('.rb', '')
MODE = ARGV[0]
SCALE = ARGV[1]
ITEM = ARGV[2].to_i

require_relative "../query_parameters/q#{QUERY}_s#{SCALE}.rb"

params = PARAMS[ITEM - 1]

substitutions = {
  'MOZAMBIQUE' => params[0],
  'UNITED KINGDOM' => params[1],
}

query = File.new("sparql_examples/#{QUERY}_#{MODE}.sparql").read

substitutions.keys.each { |k| query.gsub!(k, "@#{k}") }
substitutions.each { |k,v| query.gsub!("@#{k}", v) }

puts query
