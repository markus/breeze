Feature: ERb Configuration
  
  Server configuration files can be transformed from ERb templates
  in config/breeze/configs and deployed to any path on the server.
  This allows us to keep configuration files under revision control
  and to deploy the same configuration to multiple servers.
  
  Scenario: Transform and deploy a configuration file
    Given a file named "config/breeze/configs/test" with:
    """
    <%
      @path = 'test.conf'
      @perms = 0600
      @post = 'ls -l test.conf'
    %>
    http {
      root <%= CONFIGURATION[:app_path] %>/public
    }
    """
    When I run `thor configuration:deploy_to_localhost`
    Then the file "test.conf" should contain exactly:
    """
    
    http {
      root /srv/YOUR-APP/public
    }
    """
    And the output should contain "-rw-------"
  
  Scenario: Read and write using custom commands
    Given a file named "config/breeze/configs/test" with:
    """
    <%
      @read_cmd = 'echo "previous content"'
      @write_cmd = 'cat'
    %>
    new content
    """
    When I run `thor configuration:deploy_to_localhost`
    Then the output should contain "new content"
  
  Scenario: Define transformation order with file names
    Given a file named "config/breeze/configs/a_file" with:
    """
    <%
      @path = 'ab_test'
      @perms = 0700
    %>
    this file is transformed first and then backed up
    """
    And a file named "config/breeze/configs/b_file" with:
    """
    <%
      @path = 'ab_test'
      @perms = 0700
      @post = 'ls -l ab_test.backup'
    %>
    this overwrites the first ab_test
    """
    When I run `thor configuration:deploy_to_localhost`
    Then the file "ab_test" should contain "this overwrites the first ab_test"
    And the file "ab_test.backup" should contain "transformed first and then backed up"
    And the output should contain "-rwx------"
  
  Scenario: Transform and deploy only one file
    Given a file named "config/breeze/configs/a_file" with:
    """
    <% @path = 'a_file' %> this is a
    """
    And a file named "config/breeze/configs/b_file" with:
    """
    <% @path = 'b_file' %> this is b
    """
    When I run `thor configuration:deploy_to_localhost config/breeze/configs/b*`
    Then a file named "b_file" should exist
    And a file named "a_file" should not exist
