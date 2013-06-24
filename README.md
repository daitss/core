Core Service
==========================

Core service is comprised of the DAITSS preservation business logic and workflow web interface. It also includes the models for the DAITSS preservation and operations databases. Whereas the other DAITSS web-service components are stand alone and single purpose, Core service ties them all together to implement a digital preservation workflow.

Current Production Code
-----------------------
* https://github.com/daitss/core/tree/299045994cd9bf1cbe1b040e6ea3e44ec1cb57a0
 
Requirements
------------
* ruby (tested on 1.8.6 and 1.8.7)
* java (tested 1.6,1.7)
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
