include_recipe "logrotate"

if node["lumberjack"]["ssl_ca_certificate_path"].empty?
  Chef::Application.fatal!("You must have the CA certificate installed which signed the server's certificate")
end

group node["lumberjack"]["group"] do
  system true
end

user node["lumberjack"]["user"] do
  system true
  group node["lumberjack"]["group"]
end

case node['kernel']['machine']
when "x86_64"
    debarch="amd64"
when "i686"
    debarch="i368"
end

case node["platform_family"]
when "debian"
  cookbook_file "#{Chef::Config[:file_cache_path]}/lumberjack_#{debarch}.deb" do
    source "lumberjack_#{node["lumberjack"]["version"]}_#{debarch}.deb"
  end

  package "lumberjack" do
    source "#{Chef::Config[:file_cache_path]}/lumberjack_#{debarch}.deb"
    provider Chef::Provider::Package::Dpkg
    action :install
  end
when "rhel","fedora"
  cookbook_file "#{Chef::Config[:file_cache_path]}/lumberjack.#{node['kernel']['machine']}.rpm" do
    source "lumberjack-#{node["lumberjack"]["version"]}-1.#{node['kernel']['machine']}.rpm"
  end

  yum_package "lumberjack" do
    source "#{Chef::Config[:file_cache_path]}/lumberjack.#{node['kernel']['machine']}.rpm"
    action :install
  end
end

directory node["lumberjack"]["log_dir"] do
  mode "0755"
  owner node["lumberjack"]["user"]
  group node["lumberjack"]["group"]
  recursive true
end

logrotate_app "lumberjack" do
  cookbook "logrotate"
  path "#{node["lumberjack"]["log_dir"]}/*.log"
  frequency "daily"
  rotate 7
  create "644 root root"
end

case node["platform_family"]
when "debian"

  template "/etc/init/lumberjack.conf" do
    mode "0644"
    source "lumberjack.conf.erb"
    variables(
      :dir              => node["lumberjack"]["dir"],
      :user             => node["lumberjack"]["user"],
      :host             => node["lumberjack"]["host"],
      :port             => node["lumberjack"]["port"],
      :ssl_certificate  => node["lumberjack"]["ssl_ca_certificate_path"],
      :log_dir          => node["lumberjack"]["log_dir"],
      :files_to_watch   => node["lumberjack"]["files_to_watch"]
    )
    notifies :restart, "service[lumberjack]"
  end

  service "lumberjack" do
    provider Chef::Provider::Service::Upstart
    action [ :enable, :start ]
  end
when "rhel","fedora"
  template "/etc/init.d/lumberjack" do
    mode "0755"
    source "lumberjack.init.erb"
    variables(
      :dir              => node["lumberjack"]["dir"],
      :user             => node["lumberjack"]["user"],
      :host             => node["lumberjack"]["host"],
      :port             => node["lumberjack"]["port"],
      :ssl_certificate  => node["lumberjack"]["ssl_ca_certificate_path"],
      :log_dir          => node["lumberjack"]["log_dir"],
      :files_to_watch   => node["lumberjack"]["files_to_watch"]
    )
    notifies :restart, "service[lumberjack]"
  end

  service "lumberjack" do
    action [ :enable, :start]
  end
end
