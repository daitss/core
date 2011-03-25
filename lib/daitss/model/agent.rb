require 'data_mapper'

require 'daitss/model/account'
require 'daitss/model/event'
require 'daitss/model/request'

module Daitss

  class Agent
    include DataMapper::Resource

    property :id, String, :key => true
    property :description, Text
    property :auth_key, String
    property :salt, String, :required => true, :default => proc { rand(0x100000).to_s 26  }

    property :type, Discriminator
    property :deleted_at, ParanoidDateTime

    has n, :events
    has n, :requests

    belongs_to :account

    def encrypt_auth pass
      self.auth_key = Digest::SHA1.hexdigest("#{self.salt}:#{pass}")
    end

    def authenticate pass
      self.auth_key == Digest::SHA1.hexdigest("#{self.salt}:#{pass}") and self.deleted_at.nil?
    end

  end

  class User < Agent
    property :first_name, String
    property :last_name, String
    property :email, String
    property :phone, String
    property :address, Text
    property :is_admin_contact, Boolean, :default => false
    property :is_tech_contact, Boolean, :default => false

    def packages
      self.account.projects.packages
    end

  end

  class Contact < User
    property :permissions, Flag[:disseminate, :withdraw, :peek, :submit, :report]
  end

  class Operator < User

    has n, :entries

    def packages
      Package.all
    end

  end

  class Service < Agent; end
  class Program < Agent; end
end
