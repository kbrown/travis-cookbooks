user = "mongooseim"
pkg_name = user
home = "/usr/local/lib/#{pkg_name}"
hostname = `hostname`.strip

default[:mongooseim] = {}
default[:mongooseim][:user] = user
default[:mongooseim][:home] = home
default[:mongooseim][:hostname] = hostname
default[:mongooseim][:cookie] = "ejabberd"
default[:mongooseim][:mnesia_dir] = "#{home}/Mnesia.mongooseim@#{hostname}"
default[:mongooseim][:cluster_info] = "#{home}/.mongooseim.cluster"
default[:mongooseim][:add_to_cluster] = "#{home}/bin/add_to_cluster"

## these are updated at converge time for use in further steps
default[:mongooseim][:this_node] = nil
default[:mongooseim][:extra_db_nodes] = []
default[:mongooseim][:alive_extra_db_nodes] = []
