# DAITSSinstallManual
Page provides instructions for developers who are looking to install DAITSS on a Red Hat Enterprise Linux (RHEL) 6.x. This guide makes specific assumptions as follows:    User has a working knowledge of getting around Linux bash including switching users, running commands, navigating through directories, and basic bash commands. User is working with a pre-configured Linux Server environment or Virtual Machine that is installed and has basic configuration. User has the ability to sudo on the targeted environment

# DAITSS Dependencies
The Following dependencies are currently required to complete the DAITSS installation:

* RHEL 6.x (Install Guide written to RHEL 6.x)
* Ruby 1.9.3, Ruby Development Libraries (ruby-devel) & Ruby RDoc (ruby-rdoc)
* rubygems 1.8+
* Git - Latest
* Java OpenJDK 1.7.0_45+
* Postgres 9.x Recommended (8.x required)
* GCC GCC-C++ (4.4.7+)
* LibXML (libxml2-devel) - latest compatible with RHEL 6.x
* LibXSLT (libxslt-devel) - latest compatible with RHEL 6.x
* Libcurl (libcurl-devel) - latest compatible with RHEL 6.x
* EPEL Repository (http://download.fedoraproject.org/pub/epel/6/i386/epel-release-6-8.noarch.rpm)
* ClamAV Clamd
* RSyslog - latest compatible with RHEL 6.x
* Crontabs - latest compatible with RHEL 6.x
* Squid - latest compatible with RHEL 6.x
* Apache Dev Libraries (http-devel) - latest compatible with RHEL 6.x
* RPMForge Repository (http://packages.sw.be/rpmforge-release/rpmforge-release-0.5.2-2.el6.rf.x86_64.rpm)
* ffmpeg (requires RPMForge)
* mencoder (requires RPMForge)
* libquicktime (requires RPMForge)
* Global Gems 
** thin 1.6.2 
** sys-proctable 0.9.0 (cannot install latest versions without upgrading Ruby, sys-proctable 1.2+ requires Ruby 2+ and extensive code changes as the API changed)
* User accounts 
** daitss user with daitss user configured on postgres and sudo permissions

Note: Typically Git and GCC/GCC-C++ will already be up-to-date on most installations but this should still be verified.


## Original Installation Guide
https://daitss.pubwiki.fcla.edu/wiki/index.php/DAITSS_2_Software_Installation_Guide

## DAITSS Documentation
https://daitss.fcla.edu/content/documentation



# Step-by-step Install Guide
## Before You Begin
* Requires Red Hat Enterprise Linux (RHEL) 6.9 or CentOS 6.x, instructions written assuming using RHEL 6.9. Instructions may vary somewhat for a different distro
* Install Linux choice with desktop minimal installation as a minimum requirement
* Create daitss user that is a sudoer
* partition created and mounted @ /var/daitss/silo, owned by daitss user (this step is optional on a local VM and may not even be critical on a server environment, is dictated mostly by hardware requirements)

## Things to know
* System name referenced as '{system name}' in install instructions, replace this reference with your system name (i.e. - root@{system name} should be root@foo if your system name is foo)
* The commands will be prefaced by the user they should be executed with, so be aware of this (if a command is prefaced by 'root@system' then the command should be run by root)
* References to yum are referring to the Red Hat Package Manager yum. If installing on a linux distribution that does not use yum, obtain the appropriate RPM packages using your package manager of choice
* Commands will be followed by a description and any comments/notes

## Install Guide 
### Configure Dependencies
#### Update System
> [root@{system name}]# yum update
#### Update yum prior to installing
> [root@{system name}]# yum install ruby-1.9.3 ruby-devel-1.9.3
#### Install Ruby and Ruby Development Files (specifically requires 1.9.3)
> [root@{system name}]# yum install ruby-rdoc
#### Necessary to avoid RDoc documentation errors when installing ruby gems
> [root@{system name}]# yum install rubygems

> [root@{system name}]# gem update --system


#### Install ruby gems and update it
> [root@{system name}]# gem update --system 1.8.11
#### Needed for a deprecated method 'source_index'
> [root@{system name}]# yum install git
#### Install git (optional step if not already installed)
> [root@{system name}]# yum install java-1.7.0-openjdk java-1.7.0-openjdk-devel
#### Install Java 1.7 (latest revision of 1.7, should be 1.7.0_45 or later) open JDK
> [root@{system name}]# rpm -ivh https://download.postgresql.org/pub/repos/yum/9.6/redhat/rhel-6-x86_64/pgdg-redhat96-9.6-3.noarch.rpm

> [root@{system name}]# yum install postgresql96 postgresql96-contrib postgresql96-server postgresql96-devel


#### Download RPM and Install Postgresql 9.x
Note

Postgresql 8.4 should be sufficient, most likely a version of postgres will already be installed on your distro that will be sufficient



#### Install GCC (if not already installed)
> [root@{system name}]# yum install gcc gcc-c++


#### Install LibXML
> [root@{system name}]# yum install libxml2-devel


#### Install LibXSLT
> [root@{system name}]# yum install libxslt-devel


#### Install Libcurl
> [root@{system name}]# yum install libcurl-devel


#### Install ClamAV
> [root@{system name}]# rpm -Uvh http://download.fedoraproject.org/pub/epel/6/i386/epel-release-6-8.noarch.rpm

> [root@{system name}]# yum install clamav clamd
Note

To install ClamAV, it is first necessary to install the EPEL repository (line 1)



Install Syslog

> [root@{system name}]# yum install rsyslog


#### Install crontabs
> [root@{system name}]# yum install crontabs


#### Install Squid
> [root@{system name}]# yum install squid


#### Install Apache Dev Libraries
> [root@{system name}]# yum install httpd-devel


#### Install Preservation Tools
For 64-bit machines:

> [root@{system name}]# rpm -Uvh http://repository.it4i.cz/mirrors/repoforge/redhat/el6/en/x86_64/rpmforge/RPMS/rpmforge-release-0.5.3-1.el6.rf.x86_64.rpm


For 32-bit machines:

> [root@{system name}]# rpm -Uvh http://repository.it4i.cz/mirrors/repoforge/redhat/el6/en/x86_64/rpmforge/RPMS/rpmforge-release-0.5.3-1.el6.rf.i686.rpm
Note

These links are different from the daitss install instructions posted on the wiki



#### Install Preservation Tools
> [root@{system name}]# yum install ffmpeg

> [root@{system name}]# yum install mencoder

> [root@{system name}]# yum install libquicktime


### Java Configuration
#### Open .bashrc file to add JAVA_HOME to system path
> [root@{system name}]# vi /home/daitss/.bashrc


#### Add the following lines at the end of the file
export JAVA_HOME=/usr/java/latest (/usr/java/latest is a symbolic link to the actual location of the JAVA JDK installed on the system)
export PATH=$JAVA_HOME/bin:$PATH
Note

It is important to ensure /usr/java/latest is properly setup as a symbolic link to the openjdk install location or this will cause problems later



#### Create Symbolic Link for Latest Java Installation
> [root@{system name} ~]# ln -s /etc/alternatives/java_sdk /usr/java/latest
Note

Use desired Java Installation path in lieu of /etc/alternatives/java_sdk if java sdk is installed in a different location on the installation environment



#### Confirm Symbolic Link is Working
> [root@{system name} ~]# ls -l /usr/java/latest ~> lrwxrwxrwx. 1 root root 26 May 14 2012 /usr/java/latest -> /etc/alternatives/java_sdk


### PostgreSQL Configuration

#### Init Postgres database cluster
> [root@{system name}]# service postgresql-xx initdb
Note

xx represents postgres major/minor version, so if you have postgres 9.6 installed, the command would be service postgres-96 initdb



#### Update Postgres Host-Based Authentication Configuration File
> [root@system]# vi /var/lib/pgsql/x.x/data/pg_hba.conf
Note

x.x represents postgres major.minor version, so if you have postgres 9.6 installed, the command would be vi /var/lib/pgsql/9.6/data/pg_hba.conf



#### Replace
> local all all ident

#### With
> local all all trust


#### Replace 
> host all all 127.0.0.1/32 ident


#### With 
> host all all 127.0.0.1/32 md5


#### Replace 
> host all all ::1/128 ident


#### With 
> host all all ::1/128 md5

#### Start database service
> [root@{system name}]# service postgresql-9.x start
Note

Replace 9.x with locally used version (i.e. - if using Postgresql 9.6, use postgresql-9.6 start)



#### Create a Postgres database user.
> [root@{system name}]# su - postgres

> [postgres@{system name}]% createuser daitss


#### Start Postgres client session
> [postgres@{system name}]% psql

> postgres=# ALTER USER daitss WITH PASSWORD 'daitss';

> postgres=# \q;


#### Create Databases
> [postgres@{system name}]% createdb daitss

> [postgres@{system name}]% createdb silo_pool_db

> [postgres@{system name}]% createdb storage_master_db


#### Update bashrc
> [postgres@{system name}]% exit

> [root@{system name}]# sudo su - daitss

> [daitss@{system name}]% vi /home/daitss/.bashrc


#### Add the following
> export PATH=$JAVA_HOME/bin:/usr/{pgsql directory}/bin:$PATH

### Install Required RubyGems


#### Install bundler and sys-proctable (0.9.0 linux x86-64)
> [root@{system name}]# gem install bundler

> [root@{system name}]# gem install sys-proctable --version 0.9.0 --platform x86-64-linux


### Get DAITSS Source

#### Create DAITSS directories
> [root@{system name}]# install -d -o daitss -g daitss -m 755 /opt/web-services/sites

> [root@{system name}]# install -d -o daitss -g daitss -m 755 /opt/web-services/conf.d/thin

> [root@{system name}]# install -d -o daitss -g daitss -m 755 /var/daitss/data

> [root@{system name}]# install -d -o daitss -g daitss -m 755 /var/daitss/silo

> [root@{system name}]# install -d -o daitss -g daitss -m 755 /var/daitss/xmlresolution/collections

> [root@{system name}]# install -d -o daitss -g daitss -m 755 /var/daitss/xmlresolution/schemas

> [root@{system name}]# install -d -o daitss -g daitss -m 755 /var/log/daitss/web-services

> [root@{system name}]# install -d -o daitss -g daitss -m 755 /var/log/daitss/daemons

> [root@{system name}]# install -d -o daitss -g daitss -m 755 /var/log/daitss/submit

> [root@{system name}]# install -d -o daitss -g daitss -m 755 /var/log/daitss/thin

> [root@{system name}]# install -d -o daitss -g daitss -m 755 /var/run/daitss

> [root@{system name}]# install -d -o daitss -g daitss -m 775 /var/daitss/tmp

### Install DAITSS Core Service
#### Get Source
> [daitss@{system name}]% cd /opt/web-services/sites

> [daitss@{system name}]% git clone git://github.com/daitss/core.git


Build dependencies

> [daitss@{system name}]% cd core


#### Alter Gemfile
> [daitss@{system name}]% vi Gemfile


#### Replace 
> gem 'sys-proctable', :path => '/opt/ruby-1.8.7/lib/ruby/gems/1.8/gems/sys-proctable-0.9.0-x86-linux'


#### (64-bit) with 
> gem 'sys-proctable', :path => '/usr/lib64/ruby/gems/1.8/gems/sys-proctable-0.9.0-x86-linux'


#### (32-bit) with 
> gem 'sys-proctable', :path => '/usr/lib/ruby/gems/1.8/gems/sys-proctable-0.9.0-x86-linux'
Note

Directory may vary depending on ruby gems location on your machine



#### Install Gem Bundle
> [daitss@{system name}]% bundle install --path bundle


### Install DAITSS Actionplan Service

#### Get Source
> [daitss@{system name}]% cd /opt/web-services/sites

> [daitss@{system name}]% git clone git://github.com/daitss/actionplan.git


#### Build dependencies
> [daitss@{system name}]% cd actionplan

> [daitss@{system name}]% bundle install --path bundle


### Install DAITSS Description service
#### Get Source
> [daitss@{system name}]% cd /opt/web-services/sites

> [daitss@{system name}]% git clone git://github.com/daitss/describe.git


#### Build dependencies
> [daitss@{system name}]% cd describe

> [daitss@{system name}]% bundle install --path bundle


### Install DAITSS Silo-Pool service
#### Get Source
> [daitss@{system name}]% cd /opt/web-services/sites

> [daitss@{system name}]% git clone git://github.com/daitss/silo-pool.git


#### Build dependencies
> [daitss@{system name}]% cd silo-pool

> [daitss@{system name}]% bundle install --path bundle


### Install DAITSS Storage Master service
#### Get Source
> [daitss@{system name}]% cd /opt/web-services/sites

> [daitss@{system name}]% git clone git://github.com/daitss/store-master.git storage-master


#### Build dependencies
> [daitss@{system name}]% cd storage-master

> [daitss@{system name}]% bundle install --path bundle


### Install DAITSS Transformation service

#### Get Source
> [daitss@{system name}]% cd /opt/web-services/sites

> [daitss@{system name}]% git clone git://github.com/daitss/transform.git


#### Build dependencies
> [daitss@{system name}]% cd transform

> [daitss@{system name}]% bundle install --path bundle


### Install DAITSS Viruscheck service
#### Get Source
> [daitss@{system name}]% cd /opt/web-services/sites

> [daitss@{system name}]% git clone git://github.com/daitss/viruscheck.git


#### Build dependencies
> [daitss@system]% cd viruscheck

> [daitss@{system name}]% bundle install --path bundle


### Install DAITSS XML Resolution service
#### Get Source
> [daitss@{system name}]% cd /opt/web-services/sites

> [daitss@{system name}]% git clone git://github.com/daitss/xmlresolution.git


#### Build dependencies
> [daitss@{system name}]% cd xmlresolution

> [daitss@{system name}]% bundle install --path bundle


### Configure Logging
#### Open rsyslog to configure logging
> [daitss@{system name}]% vi /etc/rsyslog.conf


#### Add the following lines
> local0.* /var/log/daitss/common.log
#### Restart Logging
> [daitss@{system name}]% exit

> [root@{system name}]# /etc/init.d/rsyslog restart


### Configuring Apache
There are two programs involved in handling the DAITSS web microservices, Apache httpd and a simple web server written in ruby called thin.

Apache is used as reverse proxy and forwards external requests to thin servers running locally. Each of the eight DAITSS microservices are handled by its own instance of thin.

See the following illustration showing a typical request/response sequence:

![Configuration](image2018-10-25_14-23-41.png)


Apache is configured as follows: in the master apache config file, /etc/httpd/conf/httpd.conf, the following lines include our specific per-service configurations files:

> NameVirtualHost *:80

> Include /opt/web-services/conf.d/*.conf

In the directory /opt/web-services/conf.d/ are the specific apache configuration files, one for each microservice:

>    actionplan.conf

>    core.conf

>    describe.conf

>    silo.conf

>    storage-master.conf

>    transform.conf

>    viruscheck.conf

>    xmlresolution.conf

As an example, silo.conf has the following contents





>   <VirtualHost *:80>

>     ServerName silo.example.com

>     KeepAlive Off

>     ProxyPreserveHost On

>     ProxyRequests Off

>     ProxyTimeout 14400

>     <Proxy balancer://silo_servers>

>        BalancerMember http://127.0.0.1:7000

>     </Proxy>

>     ProxyPass / balancer://silo_servers/

>     ProxyPassReverse / balancer://silo_servers/

>   </VirtualHost>


This configuration causes all requests to the external interface using hostname silo.example.com to be forwarded the backend thin web server running on localhost, port 7000.

The apache configuration files for the remaining seven microservices will specify a different port, but are otherwise similar.


The thin configuration files are contained in the directory /opt/web-services/conf.d/thin/, one per microservice. The silo configuration file silo.yml has the contents:

> user: daitss

> group: daitss

> tag: silo

> environment: production

> pid: /var/run/daitss/thin/silo.pid

> log: /var/log/daitss/thin/silo.log

> port: 7000

> chdir: /opt/web-services/sites/silo-pool

> timeout: 300


The thin program will use this file to setup the environment for the silo microservice, and to start and stop the microservice. The directories specified must exist.

Note that the port in the thin configuration must match the port in the apache proxy directive. Each of eight microservices will run on its own unique port.

#### Troubleshooting
After having followed the detailed directions below and starting the thin and apache daemons, there may be problems reaching an externally-accessible webservice such as http://silo.example.com/. 

Refer to the figure above showing the request/response sequences. If there are problems, start by connecting to each microservice directly, e.g. for the silo microservice, use a browser to connect to http://localhost:7000/ to first determine if the microservice is running correctly. If not, review the log file specified in thin configuration file, for the silo example, /var/log/daitss/thin/silo.log

Once all of the microservices have been determined to be correctly working, check that the apache proxy is functioning correctly by visiting the external web service address, e.g. http://silo.examle.com/.

A very common error is to have a mismatch between the port in the apache and the thin configuration files.



#### Update httpd configuration file
> [root@{system name}]# vi /etc/httpd/conf/httpd.conf


#### Add the following lines
> NameVirtualHost *:80

> Include /opt/web-services/conf.d/*.conf


#### Configure SELinux to allow Apache to connect to other HTTP Servers running locally
> [root@{system name}]# togglesebool httpd_can_network_connect


#### Update System Hosts file
> [root@{system name}]# /etc/hosts


#### Add the following lines
> 127.0.0.1 silo.{system name}.local

> 127.0.0.1 storagemaster.{system name}.local

> 127.0.0.1 actionplan.{system name}.local

> 127.0.0.1 core.{system name}.local

> 127.0.0.1 describe.{system name}.local

> 127.0.0.1 transform.{system name}.local

> 127.0.0.1 viruscheck.{system name}.local

> 127.0.0.1 xmlresolution.{system name}.local




# DAITSS Configuration and Environment Variables


## Configuring Silo-Pool Service


Note

All of the commands in this section should be run as the daitss user, unless otherwise specified.



### Setting up DAITSS Configuration

Create the file '/opt/web-services/conf.d/daitss-config.yml' and add the following lines:

> database:

> silo_db: postgres://daitss:daitss@localhost/silo_pool_db

> silo.{system name}.local:

> log_database_queries: false

> silo_temp_directory: /var/daitss/tmp

> log_syslog_facility: LOG_LOCAL0


#### Setting up the Silo-Pool Database
> [daitss@{system name}]% cd /opt/web-services/sites/silo-pool

> [daitss@{system name}]% bundle exec tools/create-db --db-string postgres://daitss:daitss@localhost/silo_pool_db


#### Add a new silo to the database
> [daitss@{system name}]% cd /opt/web-services/sites/silo-pool

> [daitss@{system name}]% bundle exec tools/add-silos --db-string postgres://daitss:daitss@localhost/silo_pool_db --server-name "silo.{system name}.local" /var/daitss/silo

### Configuring the Silo-Pool Web Server


#### Configure Apache
Create the file '/opt/web-services/conf.d/silo.conf' with the following lines:

> <VirtualHost *:80>

>     ServerName silo.{system name}.local

>     KeepAlive Off

>     ProxyPreserveHost On

>     ProxyRequests Off

>     ProxyTimeout 14400

>     <Proxy balancer://silo_servers>

>         BalancerMember http://127.0.0.1:7000

>     </Proxy>

>     ProxyPass / balancer://silo_servers/

>     ProxyPassReverse / balancer://silo_servers/

> </VirtualHost>


#### Configure thin
Create the file '/opt/web-services/conf.d/thin/silos.yml' with the following lines:

> user: daitss

> group: daitss

> tag: silo

> environment: production

> pid: /var/run/daitss/thin/silo.pid

> log: /var/log/daitss/thin/silo.log

> port: 7000

> chdir: /opt/web-services/sites/silo-pool

> timeout: 300

## Configuring Storage Master Service


Note

All of the commands in this section should be run as the daitss user, unless otherwise specified.



### Setting up DAITSS Configuration

Open the file '/opt/web-services/conf.d/daitss-config.yml' and add the following line to the database section:

> storage_master_db: postgres://daitss:daitss@localhost/storage_master_db

Add the following lines to the end of the file:

> defaults:

> required_pools: 1

> storagemaster.{system name}.local:

> log_syslog_facility: LOG_LOCAL0

> log_database_queries: false


### Setting up the Storage Master Database

#### Initalize Storage Master database
> [daitss@{system name}]% cd /opt/web-services/sites/storage-master

> [daitss@{system name}]% bundle exec tools/create-db --db-string postgres://daitss:daitss@localhost/storage_master_db
#### Add a New Silo-Pool to the Database
> [daitss@{system name}]% cd /opt/web-services/sites/storage-master

> [daitss@{system name}]% bundle exec tools/add-pools --db-string postgres://daitss:daitss@localhost/storage_master_db silo.{system name}.local


### Configuring the Storage Master Web Server
#### Configure Apache
Create the file '/opt/web-services/conf.d/storagemaster.conf' with the following lines:

> <VirtualHost *:80>

>     ServerName storagemaster.{system name}.local

>     KeepAlive Off

>     ProxyPreserveHost On

>     ProxyRequests Off

>     ProxyTimeout 14400

>     <Proxy balancer://storagemaster_servers>

>         BalancerMember http://127.0.0.1:7100

>     </Proxy>

>     ProxyPass / balancer://storagemaster_servers/

>     ProxyPassReverse / balancer://storagemaster_servers/

> </VirtualHost>


#### Configure thin
Create the file '/opt/web-services/conf.d/thin/storagemaster.yml' with the following lines:

> user: daitss

> group: daitss

> tag: storagemaster

> environment: production

> pid: /var/run/daitss/thin/storagemaster.pid

> log: /var/log/daitss/thin/storagemaster.log

> port: 7100

> chdir: /opt/web-services/sites/storage-master

> timeout: 300

## Configuring Actionplan Service


Note

All of the commands in this section should be run as the daitss user, unless otherwise specified.



#### Setting up DAITSS configuration
Open the file '/opt/web-services/conf.d/daitss-config.yml' and add the following lines to the end of the file:

> actionplan.{system name}.local:

> log_syslog_facility: LOG_LOCAL0

### Configuring the Actionplan webserver


#### Configure Apache
Create the file '/opt/web-services/conf.d/actionplan.conf' with the following lines:

> <VirtualHost *:80>

>     ServerName actionplan.{system name}.local

>     KeepAlive Off

>     ProxyPreserveHost On

>     ProxyRequests Off

>     ProxyTimeout 14400

>     <Proxy balancer://actionplan_servers>

>         BalancerMember http://127.0.0.1:7200

>     </Proxy>

>     ProxyPass / balancer://actionplan_servers/

>     ProxyPassReverse / balancer://actionplan_servers/

> </VirtualHost>




#### Configure thin
Create the file '/opt/web-services/conf.d/thin/actionplan.yml' with the following lines:

> user: daitss

> group: daitss

> tag: actionplan

> environment: production

> pid: /var/run/daitss/thin/actionplan.pid

> log: /var/log/daitss/thin/actionplan.log

> port: 7200

> chdir: /opt/web-services/sites/actionplan

> timeout: 300



## Configuring Core Service


Note

All of the commands in this section should be run as the daitss user, unless otherwise specified.



#### Creating session-secret file
> [daitss@{system name}]% cd /opt/web-services/conf.d/

> [daitss@{system name}]% touch session-secret


### Setting up DAITSS Configuration


Open the file '/opt/web-services/conf.d/daitss-config.yml' and add the following line to the database section:

> daitss_db: postgres://daitss:daitss@localhost/daitss


Now, add the following lines to the end of the file:

> core.{system name}.local:

>     log_syslog_facility:       LOG_LOCAL0

>     submit_log_directory:      /var/log/daitss/submit

>     pulse_log_filename:        /var/log/daitss/daemons/pulse.log

>     mailer_log_filename:       /var/log/daitss/daemons/reporter.log
 
>     d1_globals_dir:             
 
>     data_dir:                  /var/daitss/data
 
>     uri_prefix:                daitss-demo://

>     http_timeout:              600
 
>     actionplan_url:            http://actionplan.{system name}.local

>     describe_service:

>           remote:              false

>           url:                 http://describe.{system name}.local

>     storage_url:               http://storagemaster.{system name}.local

>     viruscheck_url:            http://viruscheck.{system name}.local

>     transform_service:

>            remote:             false

>            url:                http://transform.{system name}.local

>            skip_undefined:     true

>     xmlresolution_url:         http://xmlresolution.{system name}.local
 
>     ingest_throttle:           1

>     dissemination_throttle:    1

>     refresh_throttle:          0

>     withdrawal_throttle:       1

>     queueing_discipline:       lifo
 
>     smtp_server:

>     max_file_size:             107374182400
 
>     jvm_options:

>       - -Xmx256m

>       - -Dhttp.proxyHost=localhost

>       - -Dhttp.proxyPort=3128




### Configuring User Environment

#### Set Environment Variables


To set these variables, open the file '/home/daitss/.bashrc' and add these lines:

> export DAITSS_CONFIG=/opt/web-services/conf.d/daitss-config.yml

> export VIRTUAL_HOSTNAME=core.{system name}.local



#### Load these changes into our current shell
> [daitss@{system name}]% source /home/daitss/.bashrc



#### Configuring Core Service Database
> [daitss@{system name}]% cd /opt/web-services/sites/core

> [daitss@{system name}]% bundle exec ./bin/init


### Configuring the Core Web Server


#### Configure Apache


Create the file '/opt/web-services/conf.d/core.conf' with the following lines:

> <VirtualHost *:80>

>     ServerName core.{system name}.local

>     KeepAlive Off

>     ProxyPreserveHost On

>     ProxyRequests Off

>     ProxyTimeout 14400

>     <Proxy balancer://core_servers>

>         BalancerMember http://127.0.0.1:7300

>     </Proxy>

>     ProxyPass / balancer://core_servers/

>     ProxyPassReverse / balancer://core_servers/

> </VirtualHost>




#### Configure thin
Create the file '/opt/web-services/conf.d/thin/core.yml' with the following lines:

> user: daitss

> group: daitss

> tag: core

> environment: production

> pid: /var/run/daitss/thin/core.pid

> log: /var/log/daitss/thin/core.log

> port: 7300

> chdir: /opt/web-services/sites/core

> timeout: 300



## Configuring Description Service
Note

All of the commands in this section should be run as the daitss user, unless otherwise specified.



### Setting up DAITSS Configuration
Open the file '/opt/web-services/conf.d/daitss-config.yml' and add the following lines to the end of the file:

> describe.{system name}.local:

>     log_syslog_facility:         LOG_LOCAL0

>     max_pdf_bitstreams: 1000
 
>     jvm_options:

>       - -Xmx256m

>       - -Dhttp.proxyHost=localhost

>       - -Dhttp.proxyPort=3128




### Configuring the Description Web Server


#### Configure Apache
Create the file '/opt/web-services/conf.d/describe.conf' with the following lines:

> <VirtualHost *:80>

>     ServerName describe.{system name}.local

>     KeepAlive Off

>     ProxyPreserveHost On

>     ProxyRequests Off

>     ProxyTimeout 14400

>     <Proxy balancer://describe_servers>

>         BalancerMember http://127.0.0.1:7400

>     </Proxy>

>     ProxyPass / balancer://describe_servers/

>     ProxyPassReverse / balancer://describe_servers/

> </VirtualHost>


#### Configure thin
Create the file '/opt/web-services/conf.d/thin/describe.yml' with the following lines:

> user: daitss

> group: daitss

> tag: describe

> environment: production

> pid: /var/run/daitss/thin/describe.pid

> log: /var/log/daitss/thin/describe.log

> port: 7400

> chdir: /opt/web-services/sites/describe

> timeout: 300


## Configuring Transformation Service
Note

All of the commands in this section should be run as the daitss user, unless otherwise specified.



### Setting up DAITSS Configuration


Open the file '/opt/web-services/conf.d/daitss-config.yml' and add the following lines to the end of the file:

> transform.{system name}.local:

>     log_syslog_facility:         LOG_LOCAL0

>     avi_norm:

>        instruction:            /usr/bin/mencoder $INPUT_FILE$ -oac pcm -ovc lavc -lavcopts vcodec=mjpeg -o $OUTPUT_FILE$

>        extension:              .avi

>        identifier:             avi/norm/v0.1.1

>        software:               MEncoder SVN-r28728-snapshot-4.1.2 (C) 2000-2009 MPlayer Team

>     wave_norm:

>        instruction:            /usr/bin/ffmpeg -i $INPUT_FILE$ -sameq -acodec pcm_s16le -y $OUTPUT_FILE$

>        extension:              .wav

>        identifier:             wave/norm/v0.1.1

>        software:               FFmpeg version , Copyright (c) 2000-2009 Fabrice Bellard, et al.

>     mov_norm:

>        instruction:            /usr/bin/lqt_transcode -ac rawaudio -vc mjpa $INPUT_FILE$ $OUTPUT_FILE$

>        extension:              .mov

>        identifier:             mov/norm/v0.1.1

>        software:               libquicktime 1.1.5, depends_lib gettext, jpeg, libiconv, libpng, zlib, ffmpeg, faac, faad2, libvorbis, libogg, lame


### Configuring the Transformation Web Server
#### Configure Apache
Create the file '/opt/web-services/conf.d/transform.conf' with the following lines:

> <VirtualHost *:80>

>     ServerName transform.shades.local

>     KeepAlive Off

>     ProxyPreserveHost On

>     ProxyRequests Off

>     ProxyTimeout 14400

>     <Proxy balancer://transform_servers>

>         BalancerMember http://127.0.0.1:7500

>     </Proxy>

>     ProxyPass / balancer://transform_servers/

>     ProxyPassReverse / balancer://transform_servers/

> </VirtualHost>


#### Configure thin
Create the file '/opt/web-services/conf.d/thin/transform.yml' with the following lines:

> user: daitss

> group: daitss

> tag: transform

> environment: production

> pid: /var/run/daitss/thin/transform.pid

> log: /var/log/daitss/thin/transform.log

> port: 7500

> chdir: /opt/web-services/sites/transform

> timeout: 300



## Configuring Viruscheck service
Note

All of the commands in this section should be run as the DAITSS user, unless otherwise specified.



### Setting up DAITSS configuration
Open the file '/opt/web-services/conf.d/daitss-config.yml' and add the following lines to the end of the file:

> viruscheck.{system name}.local:

>     log_syslog_facility:         LOG_LOCAL0


### Configuring ClamAV

#### Set SELinux to permissive mode.
As root, open the file '/etc/selinux/config'.

#### Replace the line
> SELINUX=enforcing



#### with the line
> SELINUX=permissive


Save and close the file. The changes will take effect on next reboot. To set SELINUX to permissive now, type:

> [root@{system name}]# setenforce 0


### Configure the clamd daemon to run as root
To do so, open the file '/etc/clamd.conf' and remove the following line:

> User clamav


### Configuring the Viruscheck Web Server


#### Configure Apache
Create the file '/opt/web-services/conf.d/viruscheck.conf' with the following lines:

> <VirtualHost *:80>

>     ServerName viruscheck.{system name}.local

>     KeepAlive Off

>     ProxyPreserveHost On

>     ProxyRequests Off

>     ProxyTimeout 14400

>     <Proxy balancer://viruscheck_servers>

>         BalancerMember http://127.0.0.1:7600

>     </Proxy>

>     ProxyPass / balancer://viruscheck_servers/

>     ProxyPassReverse / balancer://viruscheck_servers/

> </VirtualHost>


#### Configure thin
Create the file '/opt/web-services/conf.d/thin/viruscheck.yml' with the following lines:

> user: daitss

> group: daitss

> tag: viruscheck

> environment: production

> pid: /var/run/daitss/thin/viruscheck.pid

> log: /var/log/daitss/thin/viruscheck.log

> port: 7600

> chdir: /opt/web-services/sites/viruscheck

> timeout: 300


## Configuring XML Resolution service
Note

All of the commands in this section should be run as the daitss user, unless otherwise specified.


### Setting up DAITSS configuration
Open the file '/opt/web-services/conf.d/daitss-config.yml' and add the following lines to the end of the file:

> xmlresolution.{system name}.local:

>     log_syslog_facility:        LOG_LOCAL0

>     data_root:                  /var/daitss/xmlresolution

>     resolver_proxy:             localhost:3128


### Configuring the XML Resolution Web Server


#### Configure Apache
Create the file '/opt/web-services/conf.d/xmlresolution.conf' with the following lines:

> <VirtualHost *:80>

>     ServerName xmlresolution.{system name}.local

>     KeepAlive Off

>     ProxyPreserveHost On

>     ProxyRequests Off

>     ProxyTimeout 14400

>     <Proxy balancer://xmlresolution_servers>

>         BalancerMember http://127.0.0.1:7700

>     </Proxy>

>     ProxyPass / balancer://xmlresolution_servers/

>     ProxyPassReverse / balancer://xmlresolution_servers/

> </VirtualHost>


#### Configure thin
Create the file '/opt/web-services/conf.d/thin/xmlresolution.yml' with the following lines:

> user: daitss

> group: daitss

> tag: xmlresolution

> environment: production

> pid: /var/run/daitss/thin/xmlresolution.pid

> log: /var/log/daitss/thin/xmlresolution.log

> port: 7700

> chdir: /opt/web-services/sites/xmlresolution

> timeout: 300


## Configuring Fixity Checking
Note

All of the commands in this section should be run as the daitss user, unless otherwise specified.



### Setting up DAITSS configuration
Open the file '/opt/web-services/conf.d/daitss-config.yml' and add the following lines to the defaults section:

> fixity_expired_days:         7

> fixity_stale_days:           5


Now add the following lines to the end of the file:

> disk-fixity:

>    log_syslog_facility:         LOG_LOCAL0

>    hostname:                    silo.{system name}.local

>    pid_directory:               /var/run/daitss

>    fresh_enough:                1
 
> collect-fixities:

>    log_syslog_facility:         LOG_LOCAL0

>    server_address:              storagemaster.{system name}.local

>    pid_directory:               /var/run/daitss


### Adding Fixity Checking Entries to crontab
To add entries to start the fixity checking scripts to the system crontab, Type:

> [daitss@{system name}]% crontab -e


In the editor window, add the following lines:

> 1 1 * * * DAITSS_CONFIG=/opt/web-services/conf.d/daitss-config.yml BUNDLE_GEMFILE=/opt/web-services/sites/silo-pool/Gemfile bundle exec /opt/web-services/sites/silo-pool/tools/disk-fixity &> /dev/null

> 2 2 * * * DAITSS_CONFIG=/opt/web-services/conf.d/daitss-config.yml BUNDLE_GEMFILE=/opt/web-services/sites/storage-master/Gemfile bundle exec /opt/web-services/sites/storage-master/tools/collect-fixities &> /dev/null


## Configuring Services to run on startup

### Setup DAITSS services to run automatically on system boot
make sure all system services that DAITSS depends on start up on system boot
install the DAITSS rc script and configure it to start on boot

Configuring DAITSS dependencies to start on boot
To ensure that postgresql, clamd, httpd, squid, and rsyslog are selected to run on startup.Type:

> [root@{system name}]#chkconfig clamd on

> [root@{system name}]#chkconfig httpd on

> [root@{system name}]#chkconfig postgresql-9.2 on

> [root@{system name}]#chkconfig squid on

> [root@{system name}]#chkconfig rsyslog on


### Installing and configuring the DAITSS rc script

The first step is to copy the DAITSS rc script into '/etc/init.d:'

> [root@{system name}]# cp /opt/web-services/sites/core/bin/init.d/oss/daitss /etc/init.d


### Configure the System to run the RC script on boot
> [root@{system name}]# cd /etc/init.d

> [root@{system name}]# chkconfig --add daitss

> [root@{system name}]# chkconfig daitss on


### Add sudo Privileges to the daitss user
Open the file '/etc/sudoers' and add the following lines:

> daitss  ALL=(ALL)      ALL

> That's it! This concludes the installation.