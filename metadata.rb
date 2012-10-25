maintainer        "Hector Castro"
maintainer_email  "hectcastro@gmail.com"
license           "Apache 2.0"
description       "Installs and configures Lumberjack."
version           "0.1.0"
recipe            "lumberjack", "Installs and configures Lumberjack"

%w{ logrotate logstash }.each do |d|
  depends d
end

%w{ ubuntu }.each do |os|
    supports os
end
