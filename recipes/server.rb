if node['rstudio']['server']['arch'] == 'amd64'
    base_download_url = 'https://download2.rstudio.org'
else
    raise Exception, "This cookbook doesn't work with i386."
end

# Set up the package repository.
case node["platform"].downcase
when "ubuntu", "debian"
    include_recipe "apt"

    apt_repository "rstudio-cran" do
        uri node['rstudio']['apt']['uri']
        keyserver node['rstudio']['apt']['keyserver']
        key node['rstudio']['apt']['key']
        distribution "#{node['lsb']['codename']}/"
    end

    package "r-base" do
        action :install
    end

    package "gdebi-core" do
        action :install
    end

    remote_rstudio_server_file = "#{base_download_url}/rstudio-server-#{node['rstudio']['server']['version']}-#{node['rstudio']['server']['arch']}.deb"
    local_rstudio_server_file = "/tmp/rstudio-server-#{node['rstudio']['server']['version']}-#{node['rstudio']['server']['arch']}.deb"
    remote_file local_rstudio_server_file do
        source remote_rstudio_server_file
        action :create_if_missing
        not_if { ::File.exists?('/etc/init/rstudio-server.conf') }
    end

    execute "install-rstudio-server" do
        command "gdebi -n #{local_rstudio_server_file}"
        not_if { ::File.exists?('/etc/init/rstudio-server.conf') }
    end
end

service "rstudio-server" do
    provider Chef::Provider::Service::Upstart
    supports :start => true, :stop => true, :restart => true
    action :start
end

template "/etc/rstudio/rserver.conf" do
    source "etc/rstudio/rserver.conf.erb"
    mode 0644
    owner "root"
    group "root"
    notifies :restart, "service[rstudio-server]"
end

template "/etc/rstudio/rsession.conf" do
    source "etc/rstudio/rsession.conf.erb"
    mode 0644
    owner "root"
    group "root"
    notifies :restart, "service[rstudio-server]"
end
