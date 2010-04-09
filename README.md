DAITSS: Core Library
=====================

TODO: write this document (below is the stuff merged from the database gem)

DAITSS 2 database
==========================
This project includes
* A ruby gem for daitss2 database schema, both for fast access database and aip store
* A polling program which polls the aip records from the aip store and populates the aip records into the fast access database

Quickstart
----------
	1. Retrieve a copy of the daitss2 database.  You can either create a local git clone for it, ex.
	%git clone git://github.com/daitss/database.git
	or download a copy from the download page.

	2. Test the installation via the test harness.
	%cucumber feature/*

Requirements
------------
* ruby (tested on 1.8.6 and 1.8.7)
* cucumber (gem)
* libxml-ruby (gem)
* gemcutter(gem, a gem hosting service to publish local gems)
* jxmlvalidator (gem, an xml validator used by the aip store)
* semver (gem, provide a streamline sematic versioning for the ruby software, http://semver.org/)

License
-------
GNU General Public License

Directory Structure
-------------------
* feature: cucumber feature files
* files: contain test files for test harness.
* lib: ruby source code
* lib/db: daitss 2 database model

Usage
-----
* ruby AIPPolling.rb (to run the AIP polling)

Documentation
-------------
[development wiki](http://wiki.github.com/daitss/database/)

TESTING NOTES
=============

There are two kinds of tests in this repository:

Unit tests for:
 - workspace related code (aip, wip, sip classes and depenencies)
 - daitss libraries (authentication, operations database)

Cucumber features for integration testing

Cucumber features require the following to work properly:

 - $CONFIG set equal to path of config.yml. For more information on config.yml, look at config.example.yml.
 - $WORKSPACE set to a valid path.
 - Running test stack. This is the required set of DAITSS web services. The test stack is started with "rake services:run"
 - Database initialization. This creates the tables for the aip store and operations datasets. The database is initalized with "rake database:db_migrate"
- features/step_definitions needs to be in RUBYLIB
