require "wip"
require "wip/create"
require "template/premis"
require "uuid"

TEST_SIPS_DIR = File.join File.dirname(__FILE__), '..', 'sips'
URI_PREFIX = 'test:/'
UG = UUID.new

def submit_sip name
  sip = Sip.new File.join(TEST_SIPS_DIR, name)
  uuid = UG.generate
  path = File.join $sandbox, uuid
  uri = URI.join(URI_PREFIX, uuid).to_s
  wip = Wip.make_from_sip path, uri, sip

  wip['submit-event'] = event(:id => URI.join(wip.uri, 'event', 'submit').to_s, 
                              :type => 'submit', 
                              :outcome => 'success', 
                              :linking_objects => [ wip.uri ],
                              :linking_agents => [ 'info:fcla/daitss/test-case' ])

  wip['submit-agent'] = agent(:id => 'info:fcla/daitss/test-case',
                              :name => 'daitss test stack', 
                              :type => 'software')

  wip

end