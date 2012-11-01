include_recipe "logrotate"

if Chef::Config[:solo]
  if node["lumberjack"]["ssl_certificate"].empty?
    Chef::Application.fatal!("No Lumberjack certificate found.")
  else
    ssl_certificate = node["lumberjack"]["ssl_certificate"]
  end
else
  if node["lumberjack"]["ssl_certificate"].empty?
    results = search(:node, "roles:#{node["lumberjack"]["logstash_role"]} AND chef_environment:#{node.chef_environment}")

    if results.empty?
      Chef::Application.fatal!("No Lumberjack certificate found.")
    else
      directory"#{node["lumberjack"]["dir"]}/ssl" do
        mode "0755"
        owner node["lumberjack"]["user"]
        group node["lumberjack"]["group"]
        recursive true
      end

      file "#{node["lumberjack"]["dir"]}/ssl/ssl-cert-lumberjack.pem" do
        mode "0644"
        owner node["lumberjack"]["user"]
        group node["lumberjack"]["group"]
        content results[0]["lumberjack"]["ssl_certificate_contents"]
        notifies :restart, "service[lumberjack]"
      end

      node.set["lumberjack"]["host"]            = results[0]["fqdn"]
      node.set["lumberjack"]["ssl_certificate"] = "#{node["lumberjack"]["dir"]}/ssl/ssl-cert-lumberjack.pem"
      ssl_certificate                           = "#{node["lumberjack"]["dir"]}/ssl/ssl-cert-lumberjack.pem"
    end
  else
    ssl_certificate = node["lumberjack"]["ssl_certificate"]
  end
end

group node["lumberjack"]["group"] do
  system true
end

user node["lumberjack"]["user"] do
  system true
  shell "/bin/false"
  group node["lumberjack"]["group"]
end

cookbook_file "#{Chef::Config[:file_cache_path]}/lumberjack_amd64.deb" do
  source "lumberjack_#{node["lumberjack"]["version"]}_amd64.deb"
end

package "lumberjack" do
  source "#{Chef::Config[:file_cache_path]}/lumberjack_amd64.deb"
  provider Chef::Provider::Package::Dpkg
  action :install
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

template "/etc/init/lumberjack.conf" do
  mode "0644"
  source "lumberjack.conf.erb"
  variables(
    :dir              => node["lumberjack"]["dir"],
    :user             => node["lumberjack"]["user"],
    :host             => node["lumberjack"]["host"],
    :port             => node["lumberjack"]["port"],
    :ssl_certificate  => ssl_certificate,
    :log_dir          => node["lumberjack"]["log_dir"],
    :files_to_watch   => node["lumberjack"]["files_to_watch"]
  )
  notifies :restart, "service[lumberjack]"
end

service "lumberjack" do
  provider Chef::Provider::Service::Upstart
  action [ :enable, :start ]
end
