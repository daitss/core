require 'daitss/archive'
require 'daitss/proc/wip/from_sip'
require 'ruby-debug'

module Daitss

  class Archive

    # submit a sip on behalf of an agent
    #
    # @return [Package]
    def submit sip_path, agent, event_note = ""
      package = Package.new
      filename = File.basename(sip_path)
      if File.directory?(sip_path)
        name = filename
      else
        name = filename[0...filename.length - 4]
      end 	      
      package.sip = Sip.new :name => name

      agreement_errors = []

      # make a new sip archive
      begin
        sa = SipArchive.new sip_path #raises errors in xpath xml
                
      rescue => e 
        sa = nil
        
        agreement_errors << e.message #xml errors
        a_id = agent.account.id
        p_id = agent.account.default_project.id
      end
      
      begin
        a_id = sa.account unless a_id == agent.account.id
        p_id = sa.project unless p_id == 'default'
      rescue => e
        agreement_errors << e.message #descriptor errors (missing-account, missing-project, missing descriptor)
      end
      
      # validate account and project outside of class
      agreement_errors << "\nNot able to determine Account code in package #{filename}" if a_id == ""
      agreement_errors << "\nNot able to determine Project code in package #{filename}" if p_id == ""
      
      # determine the project to use
      if p_id != 'default' and agent.kind_of?(Operator) or agent.account.id == a_id
        account = Account.get(a_id)

        if account
          project = account.projects.first :id => p_id

          if project
            project.packages << package
          else
            agreement_errors << "\nProject code #{p_id} is not valid for account #{a_id}"
            account.default_project.packages  << package
          end

        else
          agreement_errors << "\nAccount #{a_id} does not exist in database"
          agent.account.default_project.packages  << package
        end

      elsif sa == nil and p_id == 'default'
        agent.account.default_project.packages  << package

      else
        agreement_errors << "\nCannot submit to account #{a_id}"
        agent.account.default_project.packages  << package
      end
      
      # set name to "unnamed" if sip archive was not extracted
      ###name = sa ? sa.name : "unnamed"

      package.sip = Sip.new :name => name
      package.sip.number_of_datafiles = sa.files.size rescue nil
      package.sip.size_in_bytes = sa.size_in_bytes rescue nil

      #count files if sip archive was successfully extracted
      files = []
      if sa
        Dir.glob("#{sa.path}/**") do |p|
          files.push p if File.file? p
        end
      end

      package.sip.submitted_datafiles = files.length

      # save the package and make a wip, or reject
      begin

        Package.transaction do

          unless package.save
            raise "cannot save package: #{package.id}"
          end
          

          if sa and sa.valid? and agreement_errors.empty?
            begin 
              event_note += "\n\n"
              event_note += sa.undescribed_files.map { |f| "File not listed in SIP descriptor not retained: #{f}" }.join("\n")
              wip = Wip.from_sip_archive workspace, package, sa
              package.log 'submit', :agent => agent, :notes => event_note
            end
          else
            if sa
              combined_errors = (agreement_errors + sa.errors).join "\n"
            else
              combined_errors = agreement_errors.join "\n"
            end
            event_note_sqz = event_note + '; ' + combined_errors
            event_note_sqz = event_note_sqz.squeeze("\n");
            #package.log 'reject', :agent => agent, :notes => event_note + '; ' + combined_errors
            package.log 'reject', :agent => agent, :notes => event_note_sqz
            package.queue_reject_report
          end

        end

      rescue
        FileUtils.rm_r wip.path if File.exist?(wip.path) rescue nil
        raise
      end

      package
    end

  end

end
