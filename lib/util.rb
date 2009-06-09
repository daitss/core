require 'namespace'

def import_events src, dst
  
  events = src.find('//premis:event', NS_MAP)

  events.each do |incoming_event|
    event = dst.import incoming_event

    # reassign temporary local ids
    if event.find_first('premis:eventIdentifier/premis:eventIdentifierType[normalize-space(.)="Temporary Local"]', NS_MAP)

      begin
        event.find_first('premis:eventIdentifier/premis:eventIdentifierType').content = "Permanent Local"
        event.find_first('premis:eventIdentifier/premis:eventIdentifierValue').content = next_event_id dst
      rescue
        raise "cannot re-assign identifier to event: #{event}"
      end

    end

    # find or create an samdSec
    amdSec = dst.find_first("//mets:amdSec", NS_MAP)

    if amdSec.nil?

      begin
        amdSec = XML::Node.new 'amdSec'
        fileSec = dst.find_first("//mets:fileSec", NS_MAP)
        fileSec.prev = amdSec
      rescue
        raise "cannot determine place to insert amdSec"
      end

    end

    # XML ASM FTW?
    # there must be a better way
    mdWrap = XML::Node.new 'mdWrap'
    mdWrap['MDTYPE'] = 'PREMIS'
    amdSec << mdWrap
    xmlData = XML::Node.new 'xmlData'
    mdWrap << xmlData
    xmlData << event
  end

end

def events_by_type file, type
  doc = XML::Parser.file(file).parse
  doc.find_first("//premis:event[premis:eventType[normalize-space(.)='#{type}']]", NS_MAP)
end