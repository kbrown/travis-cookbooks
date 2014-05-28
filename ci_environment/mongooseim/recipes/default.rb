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
  not_if { File.exists? "/usr/local/bin/mongooseim" }
  only_if { File.exists? "mongooseim" }
  only_if { File.exists? "mongooseim/install.mk" }
  user "root"
  code <<-EOSCRIPT
    cd mongooseim
    make
    make -f install.mk install
  EOSCRIPT
end
