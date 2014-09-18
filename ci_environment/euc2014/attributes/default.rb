user = "vagrant"
group = user

default[:euc2014] = {}
default[:euc2014][:user] = user
default[:euc2014][:group] = node.euc2014.user
default[:euc2014][:home] = "/home/#{node.euc2014.user}"
default[:euc2014][:lazy_hostname] = lambda { `hostname`.strip }
## Argh! This ought to be a host -> properties mapping from the beginning.
default[:euc2014][:hosts] = [{:name => "mim-1",
                              :ip => "172.28.128.11",
                              :roles => [:mongooseim]},
                             {:name => "mim-2",
                              :ip => "172.28.128.12",
                              :roles => [:mongooseim]},
                             {:name => "mim-3",
                              :ip => "172.28.128.13",
                              :roles => [:mongooseim]}]
