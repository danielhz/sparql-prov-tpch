
desc 'Create Virtuoso 7 container'
named_task 'create_virtuoso_7_container' do
  container = 'virtuoso7-debian9'

  puts "Lauching container #{conatiner}"
  launch_debian_container(container, '9')

  system "lxc exec #{container} -- apt install -y libssl-dev build-essential bison flex " +
         "autotools-dev automake libtool gperf gawk"

  ip = ''
  loop do
    sleep 1
    ip = container_ip(container)
    break unless ip == ''
  end

  Net::SSH.start(ip, 'debian') do |ssh|
    puts 'Getting virtuoso code'
    ssh.exec!('git clone https://github.com/openlink/virtuoso-opensource.git')

    puts 'Setup Virtuoso'
    ssh.exec!('export CFLAGS="-O2 -m64" && cd virtuoso-opensource && ' +
              './autogen.sh && ' +
              './configure --prefix=/home/debian/virtuoso-7.2.5.1 && ' +
              'make && make install')
    ssh.exec!('mkdir dataset')
    system "lxc file push config/machine_a256/virtuoso.ini #{container}/home/debian/virtuoso-7.2.5.1/var/lib/virtuoso/db/"
    puts 'Virtuoso compiled and installed'
  end

  # Publish the container
  puts 'Create a container image'
  system "lxc stop #{container}"
  system "lxc publish #{container} --alias #{container}"
end


def isql(ssh, command)
  virtuoso = 'virtuoso-7.2.5.1'
  p command
  puts command
  output = ssh.exec!("cd #{virtuoso}/bin && echo \"#{command}\" | ./isql")
  puts output
end

def isql_checkpoint(ssh)
  isql(ssh, 'checkpoint;')
  isql(ssh, 'commit work;')
  isql(ssh, 'checkpoint;')
end

def virtuoso_7_load_dataset(container)
  virtuoso = 'virtuoso-7.2.5.1'

  ip = ''
  loop do
    sleep 1
    ip = container_ip(container)
    break unless ip == ''
  end

  loop do
    sleep 1
    output = `lxc exec #{container} -- netstat -tln | grep ':22 '`
    break if output != ''
  end
  
  Net::SSH.start(ip, 'debian') do |ssh|
    output = ssh.exec!("cd #{virtuoso}/var/lib/virtuoso/db && ~/#{virtuoso}/bin/virtuoso-t")

    loop do
      sleep 1
      output = ssh.exec!('netstat | grep localhost:1111')
      ready = output.split("\n").map do |line|
        line.split.last
      end.reduce(true) do |is_connected, status|
        is_connected = (is_connected and (status == 'ESTABLISHED'))
      end
      break if ready and output != ''
    end

    isql(ssh, 'SPARQL SELECT (count(*) as ?initial_triples) WHERE { ?s ?p ?o};')
    isql(ssh, "DB.DBA.VT_BATCH_UPDATE ('DB.DBA.RDF_OBJ', 'ON', NULL);")
    isql(ssh, 'DELETE FROM DB.DBA.load_list;')
    isql(ssh, "ld_dir ('/home/debian/dataset', '*', 'http://example.org/tpch');")
    isql_checkpoint(ssh)
    isql(ssh, 'rdf_loader_run();')
    isql_checkpoint(ssh)
    isql(ssh, "DB.DBA.RDF_OBJ_FT_RULE_ADD (null, null, 'All');")
    isql(ssh, 'DB.DBA.VT_INC_INDEX_DB_DBA_RDF_OBJ ();')
    isql(ssh, 'SPARQL SELECT (count(*) as ?loaded_triples) WHERE { ?s ?p ?o };')
    isql_checkpoint(ssh)
  end
end

# %w{10 100}.each do |size|
#   desc "Create WatDiv #{size}M Virtuoso 7 container for #{scheme[:name]} reification scheme"
#   named_task "create_watdiv_#{size}M_#{scheme[:name]}_virtuoso_7_container" do
#     container = "watdiv-#{size}M-#{scheme[:name]}-virtuoso7-debian9"
#     system "lxc launch virtuoso7-debian9 #{container}"
#     scheme[:files].each do |file_pair|
#       system "lxc file push datasets/#{file_pair[0]} #{container}/home/debian/dataset/#{file_pair[1]}"
#     end
#     sleep 10
#     virtuoso_7_load_dataset(container)
#   end 
# end

virtuoso_tasks = []

Dir['datasets/ds_ttl_*'].each do |dataset|
  scale_factor = dataset.gsub('datasets/ds_ttl_', '')
  container = "tpch-#{scale_factor}-virtuoso7-debian9".gsub('.','d')
  task_name = "create-tpch-#{scale_factor}-virtuoso7-debian9"
  desc "Create #{container}"
  named_task task_name do
    system "lxc launch virtuoso7-debian9 #{container}"
    Dir["#{dataset}/*.ttl.gz"].each do |data_file|
      system "lxc file push #{data_file} #{container}/home/debian/dataset/"
    end
    virtuoso_7_load_dataset(container)
  end

  virtuoso_tasks << task_dependency(task_name)
end

task :virtuoso_tasks => virtuoso_tasks
