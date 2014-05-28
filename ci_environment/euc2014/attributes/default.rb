user = "vagrant"
group = user

default[:euc2014] = {}
default[:euc2014][:user] = user
default[:euc2014][:group] = node.euc2014.user
default[:euc2014][:home] = "/home/#{node.euc2014.user}"
default[:euc2014][:lazy_hostname] = lambda { `hostname` }
default[:euc2014][:hosts] = [{:name => "mim-1",
                              :ip => "172.28.128.11"},
                             {:name => "mim-2",
                              :ip => "172.28.128.12"},
                             {:name => "tsung-1",
                               :ip => "172.28.128.21"},
                             {:name => "tsung-2",
                              :ip => "172.28.128.22"}]
