# breeze

Breeze provides some [Thor](https://github.com/wycats/thor) tasks and example scripts for managing cloud computing resources
and deployments on [Amazon's AWS cloud](http://aws.amazon.com/). It uses [fog](https://github.com/geemus/fog) for the hard
work so it should be fairly easy to add support for other cloud computing providers that are supported by fog.

Breeze implements zero downtime deployments by moving an elastic ip from one server to another. Db migrations have to be
compatible with the previous version.

## install

    gem install breeze
    cd your-project
    breeze init

Then edit Thorfile and the stuff that got copied to config/breeze.

Management of configuration files is almost compatible with [rubber](https://github.com/wr0ngway/rubber)
but breeze does not support roles and additives. See [the rubber wiki](https://github.com/wr0ngway/rubber/wiki/Configuration)
for more information.

## create a server image

    thor server:image:create

The default install.sh compiles ruby, passenger, nginx and image magick. It takes a long time
(maybe half an hour on a small instance). It will prompt for the image name when completed.

## use it

    thor describe      # List all cloud resources that the current account can control with breeze
    
    thor staging:deploy    # Deploy a new version by replacing old servers with new ones
    thor staging:disable   # Copy maintenance.html to public/system/ on active web servers
    thor staging:enable    # Remove system/maintenance.html from active web servers
    thor staging:rollback  # Rollback the previous deploy
    thor staging:start     # Start web server and db for staging
    thor staging:stop      # Stop staging and destroy server and db

Define your staging and production in the Thorfile and the same tasks become available for both name spaces.
These tasks call app tasks with fixed parameters.

## plumbing commands

    app
    ---
    thor app:deploy PUBLIC_SERVER_NAME DB_SERVER_NAME BRANCH      # Deploy a new version by replacing old servers with new ones
    thor app:disable PUBLIC_SERVER_NAME                           # Upload system/maintenance.html to web servers
    thor app:enable PUBLIC_SERVER_NAME                            # Remove system/maintenance.html from web servers
    thor app:rollback PUBLIC_SERVER_NAME                          # Rollback a deploy
    thor app:start PUBLIC_SERVER_NAME [DB_SERVER_NAME] [DB_NAME]  # Start a new app with web server and db
    thor app:stop PUBLIC_SERVER_NAME                              # Destroy web server and db
    
    configuration
    -------------
    thor configuration:deploy_to_localhost  # Transform and deploy server configuration files to the local file system based on...
    
    db
    --
    thor db:clone OLD_DB NEW_DB           # Create a new db server using the latest backup of OLD_DB.
    thor db:create SERVER_NAME [DB_NAME]  # Create a new database server
    thor db:destroy NAME                  # Destroy a database server
    
    dns
    ---
    thor dns:record:create ZONE_ID NAME TYPE IP [TTL]  # Create a new DNS record
    thor dns:record:destroy ZONE_ID NAME [TYPE]        # Destroy a DNS record
    thor dns:zone:create DOMAIN                        # Create a new DNS zone
    thor dns:zone:destroy ZONE_ID                      # Destroy a DNS zone
    thor dns:zone:import ZONE_ID FILE                  # Creates dns records specified in FILE
    
    describe
    --------
    thor describe:addresses            # List allocated ip addresses
    thor describe:cloud_resources      # List all cloud resources that the current account can control with breeze
    thor describe:db_servers           # List database servers
    thor describe:dns_records ZONE_ID  # List all DNS records for the given zone
    thor describe:dns_zones            # Describe DNS zones
    thor describe:images               # Describe machine images owned by Breeze::CONFIGURATION[:image_owner]
    thor describe:servers              # Describe server instances
    thor describe:volumes              # Describe block store volumes (EBS)
    
    server
    ------
    thor server:address:associate IP NEW_SERVER_ID  # Associate an existing IP with a new server
    thor server:address:create SERVER_ID            # Create and associate a new elastic ip
    thor server:address:release IP                  # Release the ip address
    thor server:create                              # Launch a new server instance
    thor server:destroy INSTANCE_ID                 # Terminate a running (or stopped) server instance
    thor server:image:create                        # Launch a server with the base image, wait for it to boot, invoke...
    thor server:tag:create SERVER_ID KEY VALUE      # Create or update a tag
    thor server:tag:destroy SERVER_ID KEY           # Delete a tag
