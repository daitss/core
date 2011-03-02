require 'curb'
require 'nokogiri'

module XmlVal

  def validate f
    c = Curl::Easy.new("http://localhost:9292" + "/")
    c.multipart_form_post = true
    c.http_post(Curl::PostField.file('xml', f))
    c.response_code == 200 or raise "bad response from #{c.url}: #{c.response_code}"
    doc = Nokogiri::XML c.body_str
    warnings = scrape doc, '#warnings'
    errors = scrape doc, '#errors'
    fatals = scrape doc, '#fatals'
    [warnings, errors, fatals]
  end

  module_function :validate

  private

  def scrape doc, id
    rows = doc.search("#{id} tr")
    es = []

    rows.each do |r|
      next if r % 'th'
      e = {}
      e[:public_id] = r.at('td.public_id').content
      e[:system_id] = r.at('td.system_id').content
      e[:line] = r.at('td.line').content.to_i
      e[:column] = r.at('td.column').content.to_i
      e[:message] = r.at('td.message').content
      es << e
    end

    es
  end
  module_function :scrape

end
