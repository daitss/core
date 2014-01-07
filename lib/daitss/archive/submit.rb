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
      
      # check file size against max file size
      if File.size(sip_path) > archive.max_file_size
        agreement_errors << "This ZIP package exceeds the maximum allowed size of %.3fGB." % [ archive.max_file_size.to_f / 1073741824 ]
      end
      
      # make a new sip archive
      begin
        rescued = nil
        sa = SipArchive.new sip_path

      rescue
        sa = nil
        rescued = true
        if $!.to_s.index('\nNo such file or directory')
          agreement_errors << "\nmissing descriptor"
        elsif $!.to_s.index('Error extracting')
          agreement_errors << "\nCannot extract sip archive, must be a valid tar or zip file containing directory with sip files"
        elsif ! $!.to_s.index('Unknown archive extension')  || ! $!.to_s.index('Error extracting')
          agreement_errors << $!		
        else  
          agreement_errors <<"\nInvalid SIP descriptor. XML validation errors:" <<  $!
        end
      end


      begin 

        count = sa.multiple_agreements
        if count > 1
          rescued = true
          agreement_errors << "\nSIP descriptor contains mulitple AGREEMENT_INFO elements."
        end
        #sa.xml_initial_validation
        if !rescued
          rescued = nil
          a_id = sa.account
        end
      rescue
        rescued = true
        account = a_id
        agreement_errors << "\nNot able to determine Account code in package #{filename};"
      end 
      begin
        if !rescued	     
          p_id = sa.project
        end 
      rescue
        rescued = true
        project =  p_id
        agreement_errors << "\nNot able to determine Account code in package #{filename}"
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
            agreement_errors << "\nProject code \"#{p_id}\" is not valid for account \"#{a_id}\""
            account.default_project.packages  << package
          end

        else
          agreement_errors << "\nAccount \"#{a_id}\" does not exist"
          agent.account.default_project.packages  << package
        end

      elsif sa == nil and p_id == 'default'
        agent.account.default_project.packages  << package

      elsif !rescued
        agreement_errors << "\nYou are not authorized to submit to Account \"#{a_id}\""
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
            event_note += sa.undescribed_files.map { |f| "File not listed in SIP descriptor not retained: #{f}" }.join("\n")
            wip = Wip.from_sip_archive workspace, package, sa
            package.log 'submit', :agent => agent, :notes => event_note
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
