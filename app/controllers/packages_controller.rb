class PackagesController < ApplicationController

  def index

    @accounts = Account.all

    if params[:q]
      @query = params[:q]
      ids = @query.split
      account_id, project_id = params[:project].split '/'
      @project = Project.get project_id, account_id
      @packages = @project.packages.all(:id => ids) | @project.packages.sips.all(:name => ids).packages
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
