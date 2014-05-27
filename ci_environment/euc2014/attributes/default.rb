user = "vagrant"
group = user

default[:euc2014] = {}
default[:euc2014][:user] = user
default[:euc2014][:group] = node.euc2014.user
default[:euc2014][:home] = "/home/#{node.euc2014.user}"
