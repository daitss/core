class ProjectsController < ApplicationController

  def new
    @account = Account.get! params[:account_id]
    @project = Project.new
  end

  verify(:params => :project, :only => [:create, :update])

  def create
    @project = Project.create params[:project]

    if @project.saved?
      redirect_to(account_project_path(@project.account.id, @project.id),
                  :notice => "project #{@project.id} created")
    else
      raise "cannot save project"
    end

  end

  def update
    @project = Project.get!(params[:project][:id], params[:project][:account_id])
    @project.attributes = params[:project]

    if @project.save
      redirect_to(account_project_path(@project.account.id, @project.id),
                  :notice => "project #{@project.id} updated")
    else
      raise "cannot update project"
    end

  end

  verify(:params => [:account_id, :id], :only => [:edit, :show])

  def show
    @project = Project.get!(params[:id], params[:account_id])
  end

  def edit
    @project = Project.get!(params[:id], params[:account_id])
  end

end
