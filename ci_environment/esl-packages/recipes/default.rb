cookbook_file "esl-packages.list" do
  path "/etc/apt/sources.list.d/esl-packages.list"

  owner "root"
  group "root"
  mode "0644"
  action :create_if_missing

  notifies :run, resources(:execute => "apt-get update"), :immediately
end
