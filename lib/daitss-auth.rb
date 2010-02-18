require 'db/operations_agents'
require 'digest/sha1'
require 'pp'

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

      active = agent.active_start_date.to_time < Time.now and agent.active_end_date.to_time > Time.now
      result = AuthenticationResult.new active

      case agent.type.to_s

      when "Contact"
        result.metadata["agent_type"] = :contact 
        result.metadata["description"] = agent.description
        result.metadata["first_name"] = agent.first_name
        result.metadata["last_name"] = agent.last_name
        result.metadata["email"] = agent.email
        result.metadata["phone"] = agent.phone
        result.metadata["address"] = agent.address
        result.metadata["can_disseminate"] = agent.permissions.include? :disseminate
        result.metadata["can_withdraw"] = agent.permissions.include? :withdraw
        result.metadata["can_peek"] = agent.permissions.include? :peek
        result.metadata["can_submit"] = agent.permissions.include? :submit

        account = agent.account

        result.metadata["account_id"] = account.id
        result.metadata["account_code"] = account.code
        result.metadata["account_name"] = account.name

      when "Operator"
        puts "operator"

      when "Service"
        puts "service"

      when "Program"
        puts "program"

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

