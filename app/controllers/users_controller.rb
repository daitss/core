class UsersController < ApplicationController

  def index
    @users = User.all :order => [:account_id.desc], :active => true
  end

  def new
    @user = User.new
  end

  verify(:params => :user, :only => [:create, :update])

  def create
    @user = User.create params[:user]

    if @user.saved?
      redirect_to user_path(@user), :alert => "user #{@user.id} created"
    else
      debugger
    end

  end

  def update
    @user = User.get(params[:user][:id])
    @user.attributes = params[:user]

    if @user.save
      redirect_to user_path(@user), :alert => "user #{@user.id} updated"
    else
      debugger
    end

  end

  verify(:params => :id, :only => [:edit, :show])

  def show
    @user = User.get params[:id]
  end

  def edit
    @user = User.get params[:id]
  end

end
