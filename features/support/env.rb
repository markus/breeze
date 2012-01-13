require 'aruba/cucumber'

# We need a clean test app template that can be cloned into
# tmp/aruba for each scenario.
template_dir = File.expand_path('tmp/test_app_template')

# Create the test app with `breeze init`.
system <<-END_SCRIPT
rm -rf #{template_dir}
mkdir -p #{template_dir}
cd #{template_dir}
bundle exec ../../bin/breeze init > /dev/null
END_SCRIPT

# Remove all configuration file templates because they may contain absolute paths
# and commands that make changes to the local system.
system("rm -rf #{template_dir}/config/breeze/configs/*")

# Use the current source with bundler insted of the installed gem.
thorfile_path = File.join(template_dir, 'Thorfile')
thorfile_content = File.read(thorfile_path)
{ # replace thorfile content:
  "require 'breeze'" => "require 'bundler'; Bundler.setup; require 'breeze'",
  "'THE-NAME-OF-YOUR-KEYPAIR'" => 'nil'
}.each do |expected, wanted|
  raise "Cannot find #{expected} in #{thorfile_path}" unless thorfile_content.include?(expected)
  thorfile_content.sub!(expected, wanted)
end
File.open(thorfile_path, 'w') { |f| f.puts(thorfile_content) }

# Use Fog.mock!
system("echo 'Fog.mock!' >> #{thorfile_path}")

# Clone the test app for each scenario.
Before do
  system("cp -r #{template_dir} tmp/aruba")
  @aruba_timeout_seconds = 5
end
