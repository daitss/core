class ProjectsController < ApplicationController

  def index
    @projects = Project.all
  end

  def new
    @project = Project.new
  end

  verify(:params => :project, :only => [:create, :update])

  def create
    @project = Project.create params[:project]

    if @project.saved?
      redirect_to(account_project_path(@project.account.id, @project.id),
                  :notice => "project #{@project.id} created for #{@project.account.id}")
    else
      debugger
      true
    end

  end

  def update
    #@project = Account.get(params[:project][:account_id]).projects.first(:id => params[:project][:id])
    @project = Project.first(params[:project][:id], params[:project][:account_id])
    @project.attributes = params[:project]

    if @project.save
      redirect_to(account_project_path(@project.account.id, @project.id),
                  :notice => "project #{@project.id} updated for #{@project.account.id}")
    else
      debugger
    end

  end

  verify(:params => [:account_id, :id], :only => [:edit, :show])

  def show
    @project = Account.get(params[:account_id]).projects.first(:id => params[:id])
  end

  def edit
    @project = Account.get(params[:account_id]).projects.first(:id => params[:id])
  end

end
