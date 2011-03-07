require 'cgi'

module GoogleFontHelper

  BASE_URL = 'http://fonts.googleapis.com'

  def google_font_link_tag name, *variants
    raise ArgumentError, "name cannot be empty" if name.empty?
    raise ArgumentError, "name cannot be nil" if name.nil?

    url = BASE_URL + '/css?family='
    url += CGI.escape name.to_s
    url += ':' + variants.join(',') unless variants.empty?

    stylesheet_link_tag url, :media => nil
  end

end

ActionController::Base.class_eval do
  helper GoogleFontHelper
end
