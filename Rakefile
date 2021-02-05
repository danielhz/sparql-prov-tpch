# Tasks are defined in separate files.

require 'fileutils'
require 'net/ssh'
require './lib/sparql_bench.rb'

# require './config/config.rb'

def container_ip(container)
  `lxc list --columns n4 --format csv | grep #{container},`.
    gsub('(eth0)', '').gsub("#{container},", '').strip
end

def container_ip_loop(container)
  ip = ''
  loop do
    sleep 1
    ip = container_ip(container)
    return ip unless ip == ''
  end
end

def launch_ubuntu_container(name, version)
  system "lxc launch ubuntu:#{version} #{name}"
  system "lxc file push ~/.ssh/id_rsa.pub #{name}/home/ubuntu/.ssh/authorized_keys"
end

def launch_debian_container(name, version)
  system "lxc launch images:debian/#{version} #{name}"
  system "lxc exec #{name} apt update"
  system "lxc exec #{name} -- apt upgrade -y"
  system "lxc exec #{name} -- apt install ssh git -y"
  system "lxc exec #{name} -- apt autoremove -y"
  system "lxc exec #{name} -- adduser --home /home/debian --gecos Debian --disabled-password debian"
  system "lxc exec #{name} -- mkdir /home/debian/.ssh"
  system "lxc exec #{name} -- chmod 700 /home/debian/.ssh"
  system "lxc exec #{name} -- chown debian:debian /home/debian/.ssh"
  system "lxc file push ~/.ssh/id_rsa.pub #{name}/home/debian/.ssh/authorized_keys"
end

def task_dependency(task_name)
  "task_status/done_#{task_name}"
end

def named_task(task_name, *dependencies)
  done_task = task_dependency(task_name)
  started_task = "task_status/started_#{task_name}"

  file done_task => dependencies do
    time = Time.now
    FileUtils.touch started_task

    yield

    File.open(started_task, 'w') { |f| f.puts "#{Time.now - time}" }
    FileUtils.mv started_task, done_task
  end
end

Rake.add_rakelib 'rakelib'
