user node.mongooseim.user do
  comment "MongooseIM service account"
  home node.mongooseim.home
  shell "/bin/bash"
  system true
  action :create
end

apt_package "libexpat1-dev" do action :install end

bash "Clone MongooseIM" do
  not_if { File.exists? "mongooseim" }
  code "git clone git://github.com/esl/mongooseim -b 1.4.0"
end

template "Prepare install.mk" do
  only_if { File.exists? "mongooseim" }
  source "install.mk.erb"
  path "mongooseim/install.mk"
  mode "0664"
  owner node.euc2014.user
  group node.euc2014.user
end

bash "Install MongooseIM" do
  not_if { File.exists? "/usr/local/sbin/mongooseimctl" }
  only_if { File.exists? "mongooseim" }
  only_if { File.exists? "mongooseim/install.mk" }
  user "root"
  code <<-EOSCRIPT
    cd mongooseim
    make
    make -f install.mk install
  EOSCRIPT
end

cookbook_file "/usr/local/lib/mongooseim/bin/nodetool" do
  source "nodetool"
  mode "0550"
  owner node.mongooseim.user
  group node.mongooseim.user
  action :create
end

template "/usr/local/lib/mongooseim/etc/vm.args" do
  source "vm.args.erb"
  mode "0644"
  owner node.mongooseim.user
  group node.mongooseim.user
  variables :hostname => node.mongooseim.hostname,
            :cookie => node.mongooseim.cookie
  action :create
end

ruby_block "Add MongooseIM node to cluster" do
  only_if { File.exists? "/usr/local/bin/mongooseim" }
  only_if { File.exists? "/usr/local/lib/mongooseim/bin/nodetool" }
  only_if { alive_extra_db_nodes.any? }
  block do
    hostname = node.mongooseim.hostname
    we = node.euc2014.hosts.select {|host| host[:name] == hostname }[0]
    they = alive_extra_db_nodes()[0]
    nodetool we, "add_to_cluster", (nodename they, :mongooseim)
  end
end

def alive_extra_db_nodes
  extra_db_nodes.collect {|host| is_node_alive? host }
end

def extra_db_nodes
  hostname = node.mongooseim.hostname
  node.euc2014.hosts.select do |host|
    host[:name] != hostname and host[:roles].include? :mongooseim
  end
end

def is_node_alive? host
  "pong" == (nodetool host, "ping")
end

def nodetool host, command, *rest
  name = "-sname #{nodename host, :mongooseim}"
  cookie = "-setcookie ejabberd"
  args = "#{rest.join ' '}"
  `#{nodetool} #{name} #{cookie} #{command} #{args}`.strip
end

def nodename host, role
  "'#{role}@#{host[:name]}'"
end
