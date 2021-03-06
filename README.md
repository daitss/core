Core Service
==========================

Core service is comprised of the DAITSS preservation business logic and workflow web interface. It also includes the models for the DAITSS preservation and operations databases. Whereas the other DAITSS web-service components are stand alone and single purpose, Core service ties them all together to implement a digital preservation workflow.

Current Production Code
-----------------------
* Release 2.20.3, https://github.com/daitss/core/releases/tag/v2.20.3
 
Requirements
------------
* ruby 1.9.3 - master branch
* ruby (tested on 1.8.6 and 1.8.7) - please use ruby1.8.7 branch
* java (tested 1.6, 1.7)
* ruby-devel, rubygems, gcc and g++
* libxml2-devel, libxslt-devel, libcurl development libraries
* PostgresSQL
* Actionplan service
* Description service
* Storage Master service with configured Silo-Pools
* Transformation service
* Viruscheck service
* XML Resolution service

Installation
----------
The process of installing core service is the process of setting up a DAITSS repository. 

Instructions for installing a DAITSS repository from scratch are available here: [DAITSS installation manual](www.fcla.edu/daitss-test/installmanual.pdf)

Alternatively, a virtual machine can be downloaded that includes a fully installed and configured DAITSS repositoty here: [DAITSS demonstration virtual machine download](https://daitss.fcla.edu/content/download)

License
-------
GPL 3.0

Directory Structure
-------------------
* bin: DAITSS command-line interface scripts, init.d scripts, utilities
* features: Cucumber tests
* lib: DAITSS libraries, business logic, database models
* public: static assets
* spec: Rspec tests
* views: HAML views for web interface
* app.rb: Sinatra application
* daitss-config.example.yml: Sample DAITSS configuration file

User Documentation
-------------
A user guide is available for download here: [DAITSS user documentation](http://daitss.fcla.edu/content/documentation)
