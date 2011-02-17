require 'dm-rails/middleware/identity_map'
class ApplicationController < ActionController::Base
  use Rails::DataMapper::Middleware::IdentityMap
  protect_from_forgery

  rescue_from DataMapper::ObjectNotFoundError, :with => :not_found

  before_filter :require_login

  private

  def not_found
    render 'public/404', :status => 404, :layout => false
  end

  def require_login

    if session['current_user_id']
      @current_user = User.get session['current_user_id']
    else
      redirect_to({:controller => :login, :action => :login}, :alert => 'please login')
    end

  end

end
