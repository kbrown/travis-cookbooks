template "/etc/hosts" do
  source "etc.hosts.erb"
  mode "0644"
  owner "root"
  group "root"
  variables :hostname => node.euc2014.lazy_hostname.call,
            :hosts => node.euc2014.hosts
end
