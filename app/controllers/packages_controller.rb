class PackagesController < ApplicationController

  include DataDir

  def index
    @accounts = Account.all

    if params[:q]
      search

    elsif params[:project]
      filter

    else
      @stats = {
        :packages => Package.count,
        :files => Math::E ** 20,
        :storage => Math::E ** 30
      }
    end

  end

  verify(:params => :sip, :only => [:create])

  def create
    upload = params[:sip]
    note = params[:note] || ""
    list_id = params[:list]

    sf = SubmissionFile.new upload, @current_user.account

    begin
      sf.extract
    rescue ExtractionError => e
      render :text => e.message, :status => 400
    end

    # make a package
    @package = Package.new
    @package.sip = Sip.new :name => sf.name
    @package.lists << List.first_or_create(:id => list_id) if list_id && !list_id.empty?

    if sf.valid?

      # make the package record
      @package.project = sf.project
      @package.sip.size_in_bytes = sf.size_in_bytes
      @package.sip.number_of_datafiles = sf.files.size
      @package.requests << Request.new(:type => :ingest, :agent => @current_user)

      note += "\n\n"
      note += sf.undescribed_files.map { |f| "undescribed file: #{f}" }.join("\n")
      @package.events << Event.new(:name => 'submit', :agent => @current_user, :notes => note)

      # mv sip to submissions dir
      d = File.join submit_path, @package.id
      FileUtils.mkdir_p d
      FileUtils.mv sf.path, d
      flash[:notice] = "package #{@package.id} submitted"
    else
      @package.project = sf.project || @current_user.account.default_project

      note += '; ' + sf.errors.full_messages.join("\n")
      @package.events << Event.new(:name => 'reject', :agent => @current_user, :notes => note)
      flash[:alert] = "package #{@package.id} rejected"
    end

    @package.save or raise "cannot save package: #{@package.errors.full_messages.join ';'}"
    redirect_to package_path(@package)
  end

  def show
    @package = Package.get! params[:id]
  end

  protected

  def search
    @query = params[:q]
    ids = @query.split
    @packages = Package.all(:id => ids) | Sip.all(:name => ids).packages
  end

  def filter
    projects = case params[:project]
               when 'any' then Project.all
               else
                 account_id, project_id = params[:project].split '/'
                 Project.get! project_id, account_id
               end

    start_date = Date.new *params[:start_date].values_at(:year, :month, :day).map(&:to_i)
    end_date = Date.new *params[:end_date].values_at(:year, :month, :day).map(&:to_i)
    date_range = (start_date..end_date.tomorrow)

    events = case params[:status]
             when 'archived'
               projects.packages.events.all :timestamp => date_range, :name => 'ingest finished'

             when 'rejected'
               projects.packages.events.all :timestamp => date_range, :name => 'rejected'

             when 'withdrawn'
               projects.packages.events.all :timestamp => date_range, :name => 'withdrawn'

             when 'aborted'
               projects.packages.events.all :timestamp => date_range, :name => 'aborted'

             when 'processing'
               projects.packages.events.all :timestamp => date_range, :name.not => ['ingest finished', 'rejected', 'withdrawn', 'aborted']

             when 'any'
               projects.packages.events.all :timestamp => date_range

             else
             end

    @packages = events.packages
  end

end
