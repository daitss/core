require 'db/operations_agents'
require 'digest/sha1'
require 'pp'

#TODO: add to_xml method, unit tests

class AuthenticationResult

  @valid
  @active
  @metadata

  attr_reader :valid, :active
  attr_accessor :metadata

  def initialize active, valid = true
    @valid = valid
    @active = active

    if @valid == true
      @metadata = {}
    else
      @metadata = nil
    end
  end
end

class Authentication

  # given a id, key pair, return a data structure which contains:
  # authenticated? yes or no
  # all known metadata about agent

  def self.authenticate agent_identifier, key
    agent = OperationsAgent.first(:identifier => agent_identifier)

    if(agent.authentication_key.auth_key == sha1(key))

      # XXX temporary fix for now, DateTime from datamapper removed #to_time
      active = Time.parse(agent.active_start_date.to_s) < Time.now and Time.parse(agent.active_end_date.to_s) > Time.now
      result = AuthenticationResult.new active

      account = agent.account

      case agent

      when Contact, Operator
        result.metadata["description"] = agent.description
        result.metadata["first_name"] = agent.first_name
        result.metadata["last_name"] = agent.last_name
        result.metadata["email"] = agent.email
        result.metadata["phone"] = agent.phone
        result.metadata["address"] = agent.address

        result.metadata["account_code"] = account.code
        result.metadata["account_name"] = account.name

        if agent.class == Contact
          result.metadata["agent_type"] = :contact
          result.metadata["can_disseminate"] = agent.permissions.include? :disseminate
          result.metadata["can_withdraw"] = agent.permissions.include? :withdraw
          result.metadata["can_peek"] = agent.permissions.include? :peek
          result.metadata["can_submit"] = agent.permissions.include? :submit
        else
          result.metadata["agent_type"] = :operator
        end

      when Service
        result.metadata["agent_type"] = :service
        result.metadata["description"] = agent.description

        result.metadata["account_code"] = account.code
        result.metadata["account_name"] = account.name

      when Program
        result.metadata["agent_type"] = :program
        result.metadata["description"] = agent.description

        result.metadata["account_code"] = account.code
        result.metadata["account_name"] = account.name

      end

      return result
    else
      return AuthenticationResult.new nil, false

    end
  end

  private

  def self.sha1 string
    return Digest::SHA1.hexdigest(string)
  end
end

