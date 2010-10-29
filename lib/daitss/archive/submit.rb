require 'lib/daitss/archive'
require 'lib/daitss/proc/wip/from_sip'

module Daitss

  class Archive

    # submit a sip on behalf of an agent, return a package
    def submit sip_path, agent, event_note
      package = Package.new

      # make a new sip archive
      sa = SipArchive.new sip_path

      # validate account and project outside of class
      agreement_errors = []
      a_id = sa.account rescue nil
      p_id = sa.project rescue nil

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

      else
        agreement_errors << "cannot submit to account #{a_id}"
        agent.account.default_project.packages  << package
      end

      package.sip = Sip.new :name => sa.name
      package.sip.number_of_datafiles = sa.files.size rescue nil
      package.sip.size_in_bytes = sa.size_in_bytes rescue nil

      # save the package and make a wip, or reject
      begin

        Package.transaction do

          unless package.save
            raise "cannot save package: #{package.id}"
          end

          if sa.valid? and agreement_errors.empty?
            wip = Wip.from_sip_archive workspace, package, sa
            package.log 'submit', :agent => agent, :notes => event_note 
          else
            combined_errors = (agreement_errors + sa.errors).join "\n"
            package.log 'reject', :agent => agent, :notes => combined_errors
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

