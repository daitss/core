class UsersController < ApplicationController

  def index
    @users = User.all :order => [:account_id.desc]
  end

  def new
    @user = User.new
  end

  verify(:params => :user, :only => :create)
  def create
    @user = User.create params[:user]

    if @user.saved?
      redirect_to user_path(@user), :alert => "user #{@user.id} created"
    else
      debugger
    end

  end

  verify(:params => :id, :only => :show)
  def show
    @user = User.get params[:id]
  end

end
