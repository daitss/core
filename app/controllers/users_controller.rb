class UsersController < ApplicationController

  def index
    @active = ! (params[:inactive] == 'true')

    @users = if @active
               User.all :order => [:account_id.desc], :active => true
             else
               User.all :order => [:account_id.desc], :active => false
             end

  end

  def new
    @user = User.new
  end

  verify(:params => :user, :only => [:create, :update])

  def create
    @user = User.create params[:user]
    @user.encrypt_auth params[:password] if params[:password]

    if @user.save
      redirect_to user_path(@user), :alert => "user #{@user.id} created"
    else
      raise "cannot save user"
    end

  end

  def update
    @user = User.get!(params[:user][:id])
    @user.attributes = params[:user]
    @user.encrypt_auth params[:password]

    if @user.save
      redirect_to user_path(@user), :alert => "user #{@user.id} updated"
    else
      raise "cannot update user"
    end

  end

  verify(:params => :id, :only => [:edit, :show])

  def show
    @user = User.get! params[:id]
    #render 'public/404', :layout => false, :status => 404 unless @user
  end

  def edit
    @user = User.get! params[:id]
  end

end
