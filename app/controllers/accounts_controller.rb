class AccountsController < ApplicationController

  def index
    @accounts = Account.all
  end

  def new
    @account = Account.new
  end

  verify(:params => :account, :only => [:create, :update])

  def create

    params['account']['projects'] = [
      Project.new_default_project
    ]

    @account = Account.create params[:account]

    if @account.saved?
      redirect_to account_path(@account), :notice => "account #{@account.id} created"
    else
      raise "cannot save account"
    end

  end

  def update
    @account = Account.get!(params[:account][:id])
    @account.attributes = params[:account]

    if @account.save
      redirect_to account_path(@account), :notice => "account #{@account.id} updated"
    else
      raise "cannot update account"
    end

  end

  verify(:params => :id, :only => [:edit, :show])

  def show
    @account = Account.get! params[:id]
  end

  def edit
    @account = Account.get! params[:id]
  end

end