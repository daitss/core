class LoginController < ApplicationController
  skip_before_filter :require_login, :only => [:index, :login]

  def index
    # just show the login page
  end

  def login
    user_id = params['login']['user']
    password = params['login']['password']

    if User.authenticate user_id, password
      session['current_user_id'] = user_id
      redirect_to root_path, :notice => "welcome #{user_id}"
    else
      redirect_to :index, :alert => "invalid username or password"
    end

  end

  def logout
    session.clear
    redirect_to({:action => :index}, :notice => "goodbye #{@current_user.id}")
  end

end
