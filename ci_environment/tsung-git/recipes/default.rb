bash "Install Tsung from GitHub" do
  not_if File.exists? "/usr/local/bin/tsung"
  user "root"
  code <<-EOSCRIPT
    git clone git://github.com/processone/tsung -b v1.5.1
    cd tsung
    ./configure --prefix=/usr/local
    make
    make install
  EOSCRIPT
end
