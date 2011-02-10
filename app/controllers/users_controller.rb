class UsersController < ApplicationController

  def new
    @user = User.new
  end

  verify(:params => :user, :only => [:create, :show])
  def create
    @user = User.create params[:user]

    if @user.saved?
      redirect_to user_path(@user), :alert => "user #{@user.id} created"
    else
      debugger
    end

  end

  def show
  end

end
