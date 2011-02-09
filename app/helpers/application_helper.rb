module ApplicationHelper

  def breadcrumbs
    html = []

    html << link_to("daitss", root_path)

    case controller.controller_name
    when 'settings'
      html << link_to('settings', settings_path)
    end

    html.join(' &raquo; ').html_safe
  end

end
