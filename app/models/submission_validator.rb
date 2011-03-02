require 'service/xml_val'

class SubmissionValidator < ActiveModel::Validator

  MAX_NAME_LENGTH = 32

  def validate(sf)

    # check the max name length

    if sf.name.length > MAX_NAME_LENGTH
      sf.errors[:name] << "is too long (#{sf.name.length}) max is #{MAX_NAME_LENGTH}"
    end

    # check for missing descriptor
    unless File.file? sf.descriptor_file
      sf.errors[:descriptor] << "missing descriptor"
      return
    end

    # check for valid descriptor
    warnings, errors, fatals = XmlVal.validate(sf.descriptor_file)

    (errors + fatals).each do |e|
      sf.errors[:descriptor] << "#{e[:system_id]} #{e[:line]}: #{e[:message]}"
      return
    end

    # check for a single agreement info
    unless sf.agreement_info
      sf.errors[:descriptor] << "missing agreement info"
      return
    end

    unless sf.agreement_info_count == 1
      sf.errors[:descriptor] << "multiple agreement info"
      return
    end

    unless sf.account_id
      sf.errors[:agreement_info] << "is missing account"
    end

    unless sf.account_id == sf.agent_account.id
      sf.errors[:agreement_info] << %Q[has wrong account; expected "#{sf.agent_account.id}"; actual: "#{sf.account_id}"]
    end

    unless sf.project_id
      sf.errors[:agreement_info] << "is missing project"
    end

    unless sf.agent_account.projects.first(:id => sf.project_id)
      sf.errors[:agreement_info] << %Q[has wrong project; expected project in "#{sf.agent_account.id}"; actual: "#{sf.project_id}"]
    end

    # check content files
    Dir.chdir sf.path do
      cfs = sf.content_files_with_data

      # check for at least one content file
      unless cfs.any?
        sf.errors[:contents] << "no content files"
        return
      end

      cfs.each do |f, data|

        # check that content files exist
        unless File.exist? f
          sf.errors[:contents] << "missing content file: #{f}"
          next
        end

        # check content files' names are good
        case f
        when /^\./
          sf.errors[:content] << "invalid characters in file name: #{f}" if f =~ /^\./
        when /['"]/
          sf.errors[:content] << "invalid characters in file name: #{f}" if f =~ /['"]/
        end

        # check content files' fixity
        actual_size = File.size(f)
        if data[:size] and data[:size] != actual_size
          sf.errors[:content] << "wrong size: #{f}; expected: #{data[:size]}; actual: #{actual_size}"
        end

        actual_sha1 = Digest::SHA1.file(f).hexdigest
        if data[:sha1] and data[:sha1].downcase != actual_sha1
          sf.errors[:content] << "wrong sha1: #{f}; expected: #{data[:sha1]}; actual: #{actual_sha1}"
        end

        actual_md5 = Digest::MD5.file(f).hexdigest
        if data[:md5] and data[:md5].downcase != actual_md5
          sf.errors[:content] << "wrong md5: #{f}; expected: #{data[:md5]}; actual: #{actual_md5}"
        end

      end

    end

  end

end
