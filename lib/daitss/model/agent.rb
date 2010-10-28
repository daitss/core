require 'data_mapper'

require 'daitss/model/account'
require 'daitss/model/event'
require 'daitss/model/request'

module Daitss

  class Agent
    include DataMapper::Resource

    property :id, String, :key => true
    property :description, Text
    property :auth_key, Text

    property :type, Discriminator
    property :deleted_at, ParanoidDateTime

    has n, :events
    has n, :requests

    belongs_to :account
  end

  class User < Agent
    property :first_name, String
    property :last_name, String
    property :email, String
    property :phone, String
    property :address, String
    property :is_admin_contact, Boolean, :default => false
    property :is_tech_contact, Boolean, :default => false
  end

  class Contact < User
    property :permissions, Flag[:disseminate, :withdraw, :peek, :submit, :report]
  end

  class Operator < User; end
  class Service < Agent; end
  class Program < Agent; end
end
