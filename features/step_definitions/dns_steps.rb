Given /^I have created a DNS zone$/ do
  step 'I run `thor dns:zone:create example.com`'
  @dns_zone_id = $1 if all_stdout =~ /Zone ID: (.*)/
end

When /^I can add a record with `thor dns:record:create \[ZONE ID\] www\.example\.com\. A 127\.0\.0\.1`$/ do
  step "I run `thor dns:record:create #{@dns_zone_id} www.example.com. A 127.0.0.1`"
end
