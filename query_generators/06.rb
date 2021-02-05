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
date_max = Date.new(date_min.year + 1, date_min.month, date_min.day)
l_discount = params[1].to_f
l_discount_min = l_discount - 0.01
l_discount_max = l_discount + 0.01
l_quantity = params[2].to_i

substitutions = {
  '1993-01-01' => date_min.to_s,
  '1994-01-01' => date_max.to_s,
  '0.06' => format('%.2f', l_discount_min),
  '0.08' => format('%.2f', l_discount_max),
  '25' => l_quantity.to_s
}

query = File.new("sparql_examples/#{QUERY}_#{MODE}.sparql").read

substitutions.keys.each { |k| query.gsub!(k, "@#{k}") }
substitutions.each { |k,v| query.gsub!("@#{k}", v) }

puts query
