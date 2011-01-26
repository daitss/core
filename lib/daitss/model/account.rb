require 'dm-core'
require 'dm-constraints'
require 'dm-validations'

require 'daitss/archive'
require 'daitss/model/agent'
require 'daitss/model/project'

module Daitss

  class Account
    include DataMapper::Resource

    property :id, String, :key => true
    property :description, Text
    property :report_email, String

    has 1..n, :projects, :constraint => :destroy
    has n, :agents

    def default_project
      p = self.projects.first :id => Daitss::Archive::DEFAULT_PROJECT_ID

      unless p
        p = Project.new :id => Daitss::Archive::DEFAULT_PROJECT_ID, :account => self
        p.save
      end

      return p
    end

  end

end
