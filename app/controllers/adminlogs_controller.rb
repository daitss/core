class AdminlogsController < ApplicationController

  def index
    @adminlogs = AdminLog.all :order => [:timestamp.desc]
  end

  verify(:params => ['adminlog'], :only => :create)

  def create
    params['adminlog']['agent_id'] = @user.id
    AdminLog.raise_on_save_failure = true
    AdminLog.create params['adminlog']
    redirect_to adminlogs_path, :notice => 'admin log entry added'
  end

  verify(:params => ['id'], :only => :show)

  def show
    @entry = AdminLog.get(params['id'])
  end

end
