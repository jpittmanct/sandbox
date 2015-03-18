# Author:: Christian Vozar <cvozar@citytechinc.com>
# Cookbook Name:: openssh
# Attributes:: default
#
# Copyright 2012, CITYTECH, Inc.
# All rights reserved.

# Application attributes
default["openssh"]["port"]                     = 22
default["openssh"]["log_level"]                = "INFO"

# Authentication attributes
default["openssh"]["login_grace_time"]         = 120
default["openssh"]["permit_root_login"]        = "yes" # Options are yes or no
default["openssh"]["strict_modes"]             = "yes" # Options are yes or no
default["openssh"]["empty_passwords"]          = "no" # Options are yes or no

# Kerberos attributes
default["openssh"]["kerberos_authentication"]  = false
default["openssh"]["kerberos_get_token"]       = "no"
default["openssh"]["kerberos_or_local_passwd"] = "yes"
default["openssh"]["kerberos_ticket_cleanup"]  = "yes"

# GSSAPI attributes
default["openssh"]["gssapi_authentication"]    = false
default["openssh"]["gssapi_cleanup"]           = "yes"

default["openssh"]["ctmsp_access"]             = [ "root" ]

default["openssh"]["restart"]["minute"]        = "0"
default["openssh"]["restart"]["hour"]          = "5"
default["openssh"]["restart"]["day"]           = "1"
default["openssh"]["restart"]["month"]         = "*"
default["openssh"]["restart"]["weekday"]       = "*"

# Monthly restart cron job
default["openssh"]["restart"]["enabled"]       = true
default["openssh"]["restart"]["minute"]        = "0"
default["openssh"]["restart"]["hour"]          = "5"
default["openssh"]["restart"]["day"]           = "1"
default["openssh"]["restart"]["month"]         = "*"
default["openssh"]["restart"]["weekday"]       = "*"
