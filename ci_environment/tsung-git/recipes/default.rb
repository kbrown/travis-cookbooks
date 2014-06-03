## TODO: this should make use of roles defined in node.euc2014.hosts
if node['hostname'] =~ /tsung/
    include_recipe "tsung-git::tsung"
end
