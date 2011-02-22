class PackagesController < ApplicationController

  def index

    @accounts = Account.all

    if params[:q]
      @query = params[:q]
      ids = @query.split
      @packages = Package.all(:id => ids) | Sip.all(:name => ids).packages
    else
      @stats = {
        :packages => Package.count,
        :files => Math::E ** 20,
        :storage => Math::E ** 30
      }
    end

  end

  def search
  end

  def filter
  end

  def show
    @package = Package.get! params[:id]
  end

end
