include_recipe "logstash::server"

package "ssl-cert" do
  action :install
end

execute "generate-default-snakeoil" do
  command "make-ssl-cert generate-default-snakeoil"
  creates "/etc/ssl/certs/ssl-cert-snakeoil.pem"
end

directory "#{node["lumberjack"]["dir"]}/ssl" do
  mode "0750"
  owner node["logstash"]["user"]
  group "ssl-cert"
  recursive true
end

[ [ "certs", "pem" ], [ "private", "key" ] ].each do |pair|
  subdirectory, extension = pair

  execute "copy-certificates-#{extension}" do
    command "cp /etc/ssl/#{subdirectory}/ssl-cert-snakeoil.#{extension} #{node["lumberjack"]["dir"]}/ssl/ssl-cert-lumberjack.#{extension}"
    creates "#{node["lumberjack"]["dir"]}/ssl/ssl-cert-lumberjack.#{extension}"
  end

  file "#{node["lumberjack"]["dir"]}/ssl/ssl-cert-lumberjack.#{extension}" do
    mode (extension == "pem" ? "0644" : "640")
    owner node["logstash"]["user"]
    group "ssl-cert"
    action :touch
  end
end

ruby_block "ssl-certificate-setup" do
  block do
    node.set["lumberjack"]["ssl_key"]                  = "#{node["lumberjack"]["dir"]}/ssl/ssl-cert-lumberjack.key"
    node.set["lumberjack"]["ssl_certificate"]          = "#{node["lumberjack"]["dir"]}/ssl/ssl-cert-lumberjack.pem"
    node.set["lumberjack"]["ssl_certificate_contents"] = File.read("#{node["lumberjack"]["dir"]}/ssl/ssl-cert-lumberjack.pem")
  end
end

group "ssl-cert" do
  action :modify
  members node["logstash"]["user"]
  append true
end
