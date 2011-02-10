Given /^an admin log entry "([^"]*)"$/ do |message|
  AdminLog.raise_on_save_failure
  AdminLog.create(:message => message, :agent_id => 'root')
end
