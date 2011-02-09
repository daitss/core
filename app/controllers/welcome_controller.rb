class WelcomeController < ApplicationController
  skip_before_filter :require_login, :only => [:login, :do_login]

  def index
  end

  def login
    # just show the form if logged in, otherwise redirect to /
  end

  def do_login

    # actually log them in
    user_id = params['login']['user']
    password = params['login']['password']

    if User.authenticate user_id, password
      session['current_user_id'] = user_id
      redirect_to root_path, :notice => "welcome #{user_id}"
    else
      redirect_to :login, :alert => "invalid username or password"
    end

  end

  def logout
    session.clear
    redirect_to :login, :notice => "goodbye #{@user.id}"
  end

end
