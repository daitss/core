class PackagesController < ApplicationController

  def index

    @accounts = Account.all

    if params[:q]
      @query = params[:q]
      ids = @query.split
      @packages = Package.all(:id => ids) | Sip.all(:name => ids).packages

    elsif params[:project]

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
    else
      @stats = {
        :packages => Package.count,
        :files => Math::E ** 20,
        :storage => Math::E ** 30
      }
    end

  end

  def show
    @package = Package.get! params[:id]
  end

end
