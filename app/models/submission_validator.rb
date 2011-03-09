require 'service/xml_val'

class SubmissionValidator < ActiveModel::Validator

  MAX_NAME_LENGTH = 32

  def validate(s)

    # check the max name length

    if s.name.length > MAX_NAME_LENGTH
      s.errors[:name] << "is too long (#{s.name.length}) max is #{MAX_NAME_LENGTH}"
    end

    # check for missing descriptor
    unless File.file? s.descriptor_file
      s.errors[:descriptor] << "missing descriptor"
      return
    end

    # check for valid descriptor
    warnings, errors, fatals = XmlVal.validate(s.descriptor_file)

    (errors + fatals).each do |e|
      s.errors[:descriptor] << "#{e[:system_id]} #{e[:line]}: #{e[:message]}"
      return
    end

    # check for a single agreement info
    unless s.agreement_info
      s.errors[:descriptor] << "missing agreement info"
      return
    end

    unless s.agreement_info_count == 1
      s.errors[:descriptor] << "multiple agreement info"
      return
    end

    unless s.account_id
      s.errors[:agreement] << "is missing account"
    end

    #unless s.account_id == s.agent_account.id
      #s.errors[:agreement] << %Q[has wrong account; expected "#{s.agent_account.id}"; actual: "#{s.account_id}"]
    #end

    unless s.project_id
      s.errors[:agreement] << "is missing project"
    end

    #unless s.agent_account.projects.first(:id => s.project_id)
      #s.errors[:agreement] << %Q[has wrong project; expected project in "#{s.agent_account.id}"; actual: "#{s.project_id}"]
    #end

    # check content files
    Dir.chdir s.path do
      cfs = s.content_files_with_data

      # check for at least one content file
      unless cfs.any?
        s.errors[:contents] << "no content files"
        return
      end

      cfs.each do |f, data|

        # check that content files exist
        unless File.exist? f
          s.errors[:content] << "missing content file: #{f}"
          next
        end

        # check content files' names are good
        case f
        when /^\./
          s.errors[:content] << "invalid characters in file name: #{f}" if f =~ /^\./
        when /['"]/
          s.errors[:content] << "invalid characters in file name: #{f}" if f =~ /['"]/
        end

        # check content files' fixity
        actual_size = File.size(f)
        if data[:size] and data[:size] != actual_size
          s.errors[:content] << "wrong size: #{f}; expected: #{data[:size]}; actual: #{actual_size}"
        end

        actual_sha1 = Digest::SHA1.file(f).hexdigest
        if data[:sha1] and data[:sha1].downcase != actual_sha1
          s.errors[:content] << "wrong sha1: #{f}; expected: #{data[:sha1]}; actual: #{actual_sha1}"
        end

        actual_md5 = Digest::MD5.file(f).hexdigest
        if data[:md5] and data[:md5].downcase != actual_md5
          s.errors[:content] << "wrong md5: #{f}; expected: #{data[:md5]}; actual: #{actual_md5}"
        end

      end

    end

  end

end
