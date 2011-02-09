require 'dm-rails/middleware/identity_map'
class ApplicationController < ActionController::Base
  use Rails::DataMapper::Middleware::IdentityMap
  protect_from_forgery

  before_filter :require_login

  private

  def require_login

    if session['current_user_id']
      @user = User.get session['current_user_id']
    else
      redirect_to({:controller => :welcome, :action => :login}, :alert => 'please login')
    end

  end

end
