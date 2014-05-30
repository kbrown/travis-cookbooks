module MongooseIM

  def self.host_to_nodename host, role
    "'#{role}@#{host[:name]}'"
  end

  def self.nodename_to_host node, nodename
    role, hostname = nodename.split "@"
    node.euc2014.hosts.select do |h|
      h[:name].to_s == hostname and h[:roles].include? role.to_sym
    end[0]
  end

  def self.extra_db_nodes node
    hostname = node.mongooseim.hostname
    node.euc2014.hosts.select do |host|
      host[:name] != hostname and host[:roles].include? :mongooseim
    end
  end

  def self.this_node node
    hostname = node.mongooseim.hostname
    node.euc2014.hosts.select do |host|
      host[:name] == hostname
    end[0]
  end

end
