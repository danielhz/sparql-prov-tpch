require 'net/ssh'
require 'csv'
require 'benchmark'

class Endpoint
  attr_accessor :timeout
  
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

  # I use a double of the timeout because I manage the timeout in the service.
  def run_query(file)
    cmd = "curl -s -m #{2 * @timeout} " +
          "--data-urlencode \"query=$(cat #{file})\" " +
          "-H \"Accept: text/csv\" #{endpoint_url}"
     `#{cmd}`
  end

  # I use a double of the timeout because I manage the timeout in the service.
  def bench_query(file)
    result = []
    cmd = "curl -s -o /dev/null -w \"%{http_code}\" -m #{2 * @timeout} " +
          "--data-urlencode \"query=$(cat #{file})\" " +
          "-H \"Accept: text/csv\" #{endpoint_url}"
    time = Benchmark.measure { result << `#{cmd}` }
    [time.real] + result
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
           "--conf=/home/ubuntu/fuseki-config.ttl'"
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

def tpch_bench(endpoint, scale_factor, template, mode, times = 5)
  puts "Starting workload #{[endpoint, scale_factor, template, mode].join('-')}"
  
  endpoint.start
  queries = Dir[File.join('queries', template, mode, scale_factor, 'q*.sparql')].sort

  results = "results/#{endpoint.name}-#{scale_factor}-#{template}-#{mode}.csv"
  FileUtils.mkdir_p('results')

  puts "Checking if this query produces timeouts"
  out = endpoint.bench_query(queries.first)
  puts "result time=#{out[0]} status=#{out[1]}"
  if out[0] >= endpoint.timeout or out[1] != '200'
    puts "timeout detected"
    CSV.open(results, 'w') do |csv|
      csv << %w{engine scale_factor template mode query_id repetition time status}
      queries.each do |query|
        query_name = File.basename(query).sub(/.sparql$/, '')
        csv << [endpoint.name, scale_factor.sub('d', '.'), template, mode,
                query_name, 1, endpoint.timeout, 500]
      end
    end
    endpoint.stop
    return
  else
    puts "no timeout"
  end
  
  queries.each do |query|
    puts "warming up #{query}"
    answers = query.gsub('/', '-').sub('.sparql', '.csv').sub('queries-', "answers/#{endpoint.name}-")
    FileUtils.mkdir_p('answers')
    time = Benchmark.measure do
      File.open(answers, 'w') do |file|
        file.write endpoint.run_query(query)
      end
    end
  end

  CSV.open(results, 'w') do |csv|
    csv << %w{engine scale_factor template mode query_id repetition time status}
    (1..times).each do |repetition|
      queries.each do |query|
        puts "running query #{query} (repetition #{repetition})"
        out = endpoint.bench_query(query)
        query_name = File.basename(query).sub(/.sparql$/, '')
        csv << [endpoint.name, scale_factor.sub('d', '.'), template, mode,
                query_name, repetition, out[0], out[1]]
        csv.flush
      end
    end
  end
  
  endpoint.stop
end

