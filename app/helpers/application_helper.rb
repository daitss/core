module ApplicationHelper

  def breadcrumbs
    html = []

    html << link_to("daitss", root_path)

    case controller.controller_name
    when 'settings'
      html << link_to('settings', settings_path)

    when 'adminlogs'
      html << link_to('admin logs', adminlogs_path)

    when 'users'
      html << link_to('users', users_path)

    when 'accounts'
      html << link_to('accounts', accounts_path)

    when 'projects'
      account_id = params['account_id']
      html << link_to(account_id, account_path(account_id))

    end

    if params['id'] and %(show edit).include? controller.action_name
      html << link_to(params['id'], :action => :show, :id => params['id'])
    end

    html.join(' &raquo; ').html_safe
  end

end
