require 'net/ssh'
require 'csv'
require 'benchmark'

class Endpoint
  def initialize(container, timeout = 3000)
    @container = container
    @timeout = timeout
  end

  def container_ip
    loop do
      sleep 1
      ip = `lxc list --columns n4 --format csv | grep #{@container},`.
             gsub('(eth0)', '').gsub("#{@container},", '').strip
      return ip unless ip == ''
    end
  end

  def start
    container_start
    service_start
  end

  def container_start
    puts "Starting container #{@container}"
    system "lxc start #{@container}"
    puts 'Container started'
  end

  def stop
    system "lxc stop #{@container}"
  end

  def run_query(file)
    cmd = "curl -s -m #{@timeout} " +
          "--data-urlencode \"query=$(cat #{file})\" " +
          "-H \"Accept: text/csv\" #{endpoint_url}"
     `#{cmd}`
  end

  def bench_query(file)
    result = []
    cmd = "curl -s -o /dev/null -w \"%{http_code}\" -m #{@timeout} " +
          "--data-urlencode \"query=$(cat #{file})\" " +
          "-H \"Accept: text/csv\" #{endpoint_url}"
    time = Benchmark.measure { result << `#{cmd}` }
    [[time.real, 300].min] + result
  end
end

class LXDFusekiEndpoint < Endpoint
  def initialize(container, timeout = 300)
    super(container, timeout)
    @user = 'ubuntu'
  end

  def name
    'fuseki'
  end
    
  def endpoint_url
    "http://#{container_ip}:3030/ds/sparql"
  end
  
  def service_start
    puts "Starting service"
    system "lxc exec #{@container} -- su - ubuntu -c " +
           "'daemonize -E JVM_ARGS=${JVM_ARGS:--Xmx128G} " +
           "-c /home/ubuntu/apache-jena-fuseki-3.17.0 " +
           "-o stdout.log -e stderr.log " +
           "/home/ubuntu/apache-jena-fuseki-3.17.0/fuseki-server " +
           "--set tdb:unionDefaultGraph=true " +
           "--loc=/home/ubuntu/tdb /ds'"

    loop do
      sleep 1
      output = `lxc exec #{@container} -- netstat -tln | grep ':3030 '`
      break if output != ''
    end
    puts "Service started"
  end
end

class LXDVirtuosoEndpoint < Endpoint
  def initialize(container, timeout = 300)
    super(container, timeout)
    @user = 'debian'
  end

  def name
    'virtuoso'
  end
  
  def endpoint_url
    "http://#{container_ip}:8890/sparql/"
  end

  def service_start
    puts "Starting service"
    virtuoso = 'virtuoso-7.2.5.1'
    system "lxc exec #{@container} -- su - #{@user} -c " +
           "'cd ~/#{virtuoso}/var/lib/virtuoso/db && " +
           "~/#{virtuoso}/bin/virtuoso-t'"

    loop do
      sleep 1
      output = `lxc exec #{@container} -- netstat -tl | grep ':8890 '`
      break if output != ''
    end
    puts "Service started"
  end
end

def watdiv_bench(endpoint, size, template, scheme, mode, times = 5)
  puts "Starting workload #{[endpoint, size, template, scheme, mode].join('-')}"
  
  endpoint.start
  queries = Dir[File.join('queries', size, template, scheme, mode, '*.sparql')].sort

  queries.each do |query|
    puts "warming up #{query}"
    answers = query.gsub('/', '-').sub('.sparql', '.csv').sub('queries-', "answers/#{endpoint.name}-")
    File.open(answers, 'w') do |file|
      file.write endpoint.run_query(query)
    end
  end

  results = "results/#{endpoint.name}-#{size}-#{template}-#{scheme}-#{mode}.csv"
  CSV.open(results, 'w') do |csv|
    csv << %w{engine size template scheme mode query_id repetition time status}
    (1..times).each do |repetition|
      queries.each do |query|
        puts "running query #{query} (repetition #{repetition})"
        out = endpoint.bench_query(query)
        query_name = File.basename(query).sub(/.sparql$/, '')
        csv << [endpoint.name, size, template, scheme, mode, query_name, repetition, out[0], out[1]]
      end
    end
  end
  
  endpoint.stop
end

class TripleProvEndpoint
  def initialize
    @home = '/home/ubuntu/sparql-prov-watdiv/tripleprov_demo/release'
  end

  def name
    'tripleprov'
  end

  def bench_query(file)
    output = `cd #{@home} && ./tripleprov #{file}`
    {body: output, time: output.lines.last.split.last}
  end
end

def tripleprov_bench(size, template, times = 5)
  endpoint = TripleProvEndpoint.new
  scheme = 'namedgraphs'
  mode = 'T'
  
  puts "Starting workload #{[endpoint.name, size, template, scheme, mode].join('-')}"

  # tp.bench_query('/home/ubuntu/sparql-prov-watdiv/queries/10M/S2/namedgraphs/T/00.sparql')

  queries = Dir[File.join('queries', size, template, scheme, mode, '*.sparql')].sort

  results = "results/#{endpoint.name}-#{size}-#{template}-#{scheme}-#{mode}.csv"
  CSV.open(results, 'w') do |csv|
    csv << %w{engine size template scheme mode query_id repetition time status}
    queries.each do |query|
      (1..times).each do |repetition|
        puts "Running query #{query} (repetition #{repetition})"
        result = endpoint.bench_query(File.absolute_path query)
        
        answers = query.gsub('/', '-').sub('.sparql', '.csv').sub('queries-', "answers/#{endpoint.name}-")
        File.open(answers, 'w') do |file|        
          file.puts result[:body]
        end

        query_name = File.basename(query).sub(/.sparql$/, '')
        csv << [endpoint.name, size, template, scheme, mode, query_name, repetition, result[:time], 200]
      end
    end
  end
end
