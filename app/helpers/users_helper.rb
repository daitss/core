module UsersHelper

  def gravatar user, options={}
    email_hash = Digest::MD5.hexdigest( user.email || user.id )
    url = "http://www.gravatar.com/avatar/#{email_hash}?d=mm"

    url += "&s=#{options[:size]}" if options[:size]

    image_tag url
  end

  def roles user
    roles = []
    roles << 'technical' if user.is_tech_contact
    roles << 'adminitrative' if user.is_admin_contact
    roles << 'none' if roles.empty?
    roles.join ' & '
  end

end
