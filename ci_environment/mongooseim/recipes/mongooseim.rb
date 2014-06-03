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
  mode "0554"
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

file "#{node.mongooseim.home}/.erlang.cookie" do
  mode "0600"
  owner node.mongooseim.user
  group node.mongooseim.user
  action :create
  content node.mongooseim.cookie
end

file node.mongooseim.cluster_info do
  mode "0664"
  owner node.mongooseim.user
  group node.mongooseim.user
  action :create
  content ""
end

bash "Detect MongooseIM cluster configuration 1 of 2" do
  user node.mongooseim.user
  group node.mongooseim.user
  environment 'HOME' => node.mongooseim.home

  node.mongooseim.this_node = MongooseIM.this_node node
  node.mongooseim.extra_db_nodes = MongooseIM.extra_db_nodes node

  cluster_info = node.mongooseim.cluster_info
  extra_db_nodes = node.mongooseim.extra_db_nodes
  escript_nodetool = "escript /usr/local/lib/mongooseim/bin/nodetool"

  code <<-EOF
  for node in #{extra_db_nodes.map{|n| n[:name]}.join "\n"}
  do
    echo -n mongooseim@$node >> #{cluster_info}
    echo -n "\t" >> #{cluster_info}
    #{escript_nodetool} -sname mongooseim@$node \
                        -setcookie #{node.mongooseim.cookie} \
        && echo pong >> #{cluster_info} \
        || echo pang >> #{cluster_info}
  done
  EOF
end

ruby_block "Detect MongooseIM cluster configuration 2 of 2" do
  cluster_info = node.mongooseim.cluster_info
  block do
    alive = node.mongooseim.alive_extra_db_nodes
    File.open(cluster_info, "r").each do |line|
      if line =~ /pong/ then
        alive.push(MongooseIM.nodename_to_host node, line.split[0])
      end
    end
  end
end

ruby_block "Create add_to_cluster script" do
  only_if { File.exists? "/usr/local/lib/mongooseim/bin/nodetool" }

  escript_nodetool = "escript /usr/local/lib/mongooseim/bin/nodetool"
  cookie = node.mongooseim.cookie
  block do
    we = MongooseIM.host_to_nodename(node.mongooseim.this_node,
                                     "mongooseim")
    they = node.mongooseim.alive_extra_db_nodes[0]
    unless they.nil?
      they = MongooseIM.host_to_nodename(they, "mongooseim")
      File.open(node.mongooseim.add_to_cluster, "w") do |file|
        file.write <<-EOF
        #!/bin/bash
        cd #{node.mongooseim.home}
        #{escript_nodetool} -exact_sname #{we} -setcookie #{cookie} add_to_cluster #{they}
        EOF
      end
      FileUtils.chown(node.mongooseim.user,
                      node.mongooseim.user,
                      [node.mongooseim.add_to_cluster])
      FileUtils.chmod(0555, node.mongooseim.add_to_cluster)
    else
      f = node.mongooseim.add_to_cluster
      FileUtils.rm([f]) if File.exists? f
    end

  end
end

#bash "Add MongooseIM node to cluster" do
#  only_if { File.exists? node.mongooseim.add_to_cluster }

#  user node.mongooseim.user
#  group node.mongooseim.user
#  environment "HOME" => node.mongooseim.home,
#              "PATH" => "#{node.mongooseim.home}/bin"
#  cwd node.mongooseim.home
#  path ["#{node.mongooseim.home}/bin"]

#  code node.mongooseim.add_to_cluster
#end

## Essentially, it doesn't matter whether this script is run from a file
## or just created and executed on the fly as it still needs to be done from
## a Ruby block and the final Mnesia dir permissions need to be set manually.
##
## Using a `bash` resource seems easier at the first thought,
## but in fact that won't work, since we need to fetch the options from
## a file before we can craft the script to run.
## This needs to be done in a Ruby block executed at convergence time.
## Moreover, the `bash` resource couldn't find a pregenerated script
## (see commented out block above).
##
## In other words, this code block could be merged with
## ruby_block "Create add_to_cluster script",
## but a `bash` block in its place won't be sufficient.
##
## > Mnesia dir permissions need to be set manually.
## Why? Because we can't use `user`/`group` attributes with a Ruby
## block resource.
##
## Remember, without redirecting the output of add_to_cluster to file,
## the script doesn't work. Why?
ruby_block "Add MongooseIM node to cluster" do
  only_if { File.exists? node.mongooseim.add_to_cluster }
  not_if { File.exists? node.mongooseim.mnesia_dir }
  block do
    user = node.mongooseim.user
    mnesia_dir = node.mongooseim.mnesia_dir
    `#{node.mongooseim.add_to_cluster} > /tmp/add_to_cluster.out`
    FileUtils.chown_R(user, user, [mnesia_dir])
  end
end

## This block proves that user/group attributes actually
## work OK when creating new files.
#bash "experiment" do
#  user node.mongooseim.user
#  group node.mongooseim.user
#  cwd node.mongooseim.home

#  code <<-EOF
#  touch experiment
#  bin/make-experiment-2
#  EOF
#end
