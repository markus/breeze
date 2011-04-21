Given /^I have started a server$/ do
  When "I run `thor server:create`"
  @started_server_id = $1 if all_stdout =~ /server (i-[^.])\.\.\./
end

Then /^I can terminate the server with `thor server:destroy \[SERVER ID\] \-\-force`$/ do
  Then "I successfully run `thor server:destroy #{@started_server_id} --force`"
end
