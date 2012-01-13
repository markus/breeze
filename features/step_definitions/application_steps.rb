Given /^I have an empty working directory$/ do
  step "I run `rm -rf config Thorfile`"
end

Given /^my Thorfile contains access credentials and configuration$/ do
  # the Thorfile should be okay already, just check it
  check_file_content('Thorfile', "CONFIGURATION", true)
end

Then /^the output should look like:$/ do |lines|
  lines.each_line do |line|
    all_output.should match(/#{line.strip}/)
  end
end
