require 'datafile'

class DataFile

  def obsolete!
    raise "#{self} is already obsolete" if obsolete?

    metadata['obsolete-event'] = event({
      :id => "#{uri}/event/obsolete",
      :type => 'obsolete',
      :linking_objects => [uri]
    })
  end

  def obsolete?

    metadata.has_key?('obsolete-event') or old_events.any? do |doc|
      doc.find "//P:eventType = 'obsolete'", NS_PREFIX
    end

  end

end
