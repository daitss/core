require 'daitss/archive'
require 'daitss/proc/wip/from_sip'

module Daitss

  class Archive

    # submit a sip on behalf of an agent
    #
    # @return [Package]
    def submit sip_path, agent, event_note = ""
      package = Package.new

      agreement_errors = []

      # make a new sip archive
      begin
        sa = SipArchive.new sip_path
	sa.xml_initial_validation
	a_id = sa.account
        p_id = sa.project
      rescue
        sa = nil
	if $!.to_s.index('No such file or directory')
           agreement_errors << "missing descriptor"
	elsif $!.to_s.index('error extracting')
           agreement_errors << "cannot extract sip archive, must be a valid tar or zip file containing directory with sip files"
	else   
	  agreement_errors << $!
	end  
	

        a_id = agent.account.id
        p_id = agent.account.default_project.id
      end
      # validate account and project outside of class

      # determine the project to use
      if p_id != 'default' and agent.kind_of?(Operator) or agent.account.id == a_id
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

      else
        agreement_errors << "cannot submit to account #{a_id}"
        agent.account.default_project.packages  << package
      end

      # set name to "unnamed" if sip archive was not extracted
      name = sa ? sa.name : "unnamed"

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
