default["lumberjack"]["version"]                    = "0.0.25"
default["lumberjack"]["user"]                       = "lumberjack"
default["lumberjack"]["group"]                      = "lumberjack"
default["lumberjack"]["dir"]                        = "/opt/lumberjack"
default["lumberjack"]["log_dir"]                    = "#{node["lumberjack"]["dir"]}/log"
default["lumberjack"]["host"]                       = "localhost"
default["lumberjack"]["port"]                       = "6060"
default["lumberjack"]["ssl_ca_certificate_path"]    = ""
default["lumberjack"]["files_to_watch"]             = [ "/var/log/syslog" ]
default["lumberjack"]["logstash_role"]              = "logstash_server"
default["lumberjack"]["logstash_fqdn"]              = ""
