class SettingsController < ApplicationController
  verify(:params => 'settings',
         :only => :update,
         :reditrect_to => { :action => "settings" })

  def edit
    @servers = Setting.all :id.like => '% server'
    @non_servers = Setting.all - @servers
  end

  def update

    params[:settings].each do |id, value|
      s = Setting.get(id)
      s.update :value => value unless s.value == value
    end

    flash[:notice] = 'settings updated'
    redirect_to :action => :edit
  end

end
