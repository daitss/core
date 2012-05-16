require 'daitss/archive'
require 'daitss/proc/wip/from_sip'

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
        rescued = nil
        sa = SipArchive.new sip_path

      rescue
        sa = nil
        rescued = true
        if $!.to_s.index('No such file or directory')
          agreement_errors << "missing descriptor"
        elsif $!.to_s.index('rror extracting')
          agreement_errors << "\nCannot extract sip archive, must be a valid tar or zip file containing directory with sip files"
        else
          agreement_errors <<"Invalid SIP descriptor. XML validation errors:" <<  $!
          #agreement_errors  <<  $!
	end
      end


      begin 
        
	count = sa.multiple_agreements
	if count > 1
	  rescued = true
	  agreement_errors << "multiple agreements"
	end
        #sa.xml_initial_validation
	if !rescued
	  rescued = nil
	  a_id = "UnknownAccount"
	  a_id = sa.account
	end
      rescue
	      rescued = true
	      account = a_id
	      agreement_errors << "Not able to determine Account code in package #{filename};"
      end 
     begin
      if !rescued	     
        p_id = "UnknownProject"
        p_id = sa.project
      end 
    rescue
      rescued = true
      project =  p_id
      agreement_errors << "Package #{filename} not able to determine project Account: #{a_id} Project: #{p_id}"
    end 
    begin
      sa.xml_initial_validation unless rescued
      rescue
	agreement_errors <<  $!      
        sa = nil
      end
      # validate account and project outside of class

      # determine the project to use
      if !rescued && (p_id != 'default' and agent.kind_of?(Operator) or agent.account.id == a_id)
        account = Account.get(a_id)

        if account
          project = account.projects.first :id => p_id

          if project
            project.packages << package
          else
            agreement_errors << "no project #{p_id} for account #{a_id}"
            account.default_project.packages  << package
          end

        else
          agreement_errors << "no account #{a_id}"
          agent.account.default_project.packages  << package
        end

      elsif sa == nil and p_id == 'default'
        agent.account.default_project.packages  << package

      elsif !rescued
        agreement_errors << "\nCannot submit to account #{a_id}"
        agent.account.default_project.packages  << package
      else
	 agent.account.default_project.packages  << package     
      end
      # set name to "unnamed" if sip archive was not extracted
      ####name = sa ? sa.name : "unnamed"

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
            event_note += "\n\n"
            event_note += sa.undescribed_files.map { |f| "undescribed file: #{f}" }.join("\n")
            wip = Wip.from_sip_archive workspace, package, sa
            package.log 'submit', :agent => agent, :notes => event_note
          else
            if sa
              combined_errors = (agreement_errors + sa.errors).join "\n"
            else
              combined_errors = agreement_errors.join "\n"
            end

            package.log 'reject', :agent => agent, :notes => event_note + '; ' + combined_errors
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
