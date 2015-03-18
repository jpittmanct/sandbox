maintainer       "CITYTECH, Inc."
maintainer_email "support@ctmsp.com"
license          "All rights reserved"
description      "Installs/Configures OpenSSH"
version          "1.0.0"

# Operating systems supported
%w{ redhat centos fedora ubuntu debian arch }.each do |os|
  supports os
end