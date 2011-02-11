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

    end

    if controller.action_name == 'show'
      html << link_to(params['id'], '#')
    end

    html.join(' &raquo; ').html_safe
  end

end
