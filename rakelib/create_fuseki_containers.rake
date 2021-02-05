
desc 'Create Fuseki 3 container'
named_task 'create_fuseki_3_container' do
  container = 'fuseki3-ubuntu2004'

  puts "Lauching container #{conatiner}"
  launch_ubuntu_container(container, '20.04')

  puts 'Install required system packages'
  system "lxc exec #{container} -- apt install -y default-jdk daemonize net-tools"

  puts 'Connecting to container via ssh'
  Net::SSH.start(container_ip_loop(container), 'ubuntu') do |ssh|
    tars = %w{apache-jena-3.17.0.tar.gz apache-jena-fuseki-3.17.0.tar.gz}
    mirror = 'https://mirrors.dotsrc.org/apache/jena/binaries'

    tars.each do |tar|
      ssh.exec!("curl #{mirror}/#{tar} --output #{tar}")
      ssh.exec!("tar -xzf #{tar}")
    end

    ssh.exec!("mkdir dataset")
    ssh.exec!("mkdir tdb")
  end
  
  puts 'Create the container image'
  system "lxc stop #{container}"
  system "lxc publish #{container} --alias #{container}"
end

# %w{10 100}.each do |size|
#   [
#     {
#       name: 'namedgraphs',
#       files: [["watdiv.#{size}M-namedgraphs.nt.gz", "watdiv.#{size}M-namedgraphs.nq.gz"]]
#     },
#     {
#       name: 'rdf',
#       files: [
#         ["watdiv.#{size}M-rdf.nt.gz", "watdiv.#{size}M-rdf.nt.gz"],
#         ["watdiv.#{size}M.nt.gz", "watdiv.#{size}M.nt.gz"]
#       ]
#     },
#     {
#       name: 'wikidata',
#       files: [
#         ["watdiv.#{size}M-wikidata.nt.gz", "watdiv.#{size}M-wikidata.nt.gz"],
#         ["watdiv.#{size}M.nt.gz", "watdiv.#{size}M.nt.gz"]
#       ]
#     }
#   ].each do |scheme|
#     desc "Create WatDiv #{size}M Fuseki 3 container for #{scheme[:name]} reification scheme"
#     named_task "create_watdiv_#{size}M_#{scheme[:name]}_fuseki_3_container" do
#       image = 'fuseki3-ubuntu2004'
#       container = "watdiv-#{size}M-#{scheme[:name]}-#{image}"
#       user = 'ubuntu'
#       system "lxc launch #{image} #{container}"
#       scheme[:files].each do |file_pair|
#         system "lxc file push datasets/#{file_pair[0]} #{container}/home/#{user}/dataset/#{file_pair[1]}"
#       end
#       sleep 15
#       puts 'Connecting to container via ssh'
#       Net::SSH.start(container_ip_loop(container), user) do |ssh|
#         puts 'Loading data'
#         ssh.exec!("apache-jena-3.17.0/bin/tdbloader2 --loc tdb dataset/* > load-1.log 2> load-2.log")
#       end
#     end
#   end
# end


fuseki_tasks = []

Dir['datasets/ds_ttl_*'].each do |dataset|
  user = 'ubuntu'
  scale_factor = dataset.gsub('datasets/ds_ttl_', '')
  container = "tpch-#{scale_factor}-fuseki3-ubuntu2004".gsub('.','d')
  task_name = "create-tpch-#{scale_factor}-fuseki3-ubuntu2004"
  desc "Create #{container}"
  named_task task_name do
    system "lxc launch fuseki3-ubuntu2004 #{container}"
    Dir["#{dataset}/*.ttl.gz"].each do |data_file|
      system "lxc file push #{data_file} #{container}/home/#{user}/dataset/"
    end

    puts 'Connecting to container via ssh'
    loop do
      sleep 1
      output = `lxc exec #{container} -- netstat -tln | grep ':22 '`
      break if output != ''
    end
    Net::SSH.start(container_ip_loop(container), user) do |ssh|
      puts 'Loading data'
      ssh.exec!("apache-jena-3.17.0/bin/tdbloader2 --loc tdb dataset/* > load-1.log 2> load-2.log")
    end
  end

  fuseki_tasks << task_dependency(task_name)
end

task :fuseki_tasks => fuseki_tasks
