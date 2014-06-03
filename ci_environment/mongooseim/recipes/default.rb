## TODO: this should make use of roles defined in node.euc2014.hosts
if node['hostname'] =~ /mim/
    include_recipe "mongooseim::mongooseim"
end
