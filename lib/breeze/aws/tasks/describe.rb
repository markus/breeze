module Breeze
  module Aws

    # The class name is a bit weird, but task names are okay:
    #   aws:describe:instances
    # We want plural nouns here, other namespaces are singular:
    #   aws:instance:launch
    class Describe < AwsVeur

      default_task :all
      desc :all, 'List all AWS resources that the current account can control with breeze'
      def all
        images
        instances
        volumes
      end

      desc :images, 'Describe Amazon Machine Images (AMIs) owned by Breeze::CONFIGURATION[:ami_owners]'
      def images
        images = aws.describe_images(:owner_id => CONFIGURATION[:ami_owners])
        images = images.array('imagesSet item')
        images.each do |i|
          i['_name_or_location'] = i['name'] || i['imageLocation']
          i['_type'] = [i['imageType'], i['architecture'], i['rootDeviceType']].compact.join(', ')
        end
        report_spec = [
          ['Image ID', 'imageId'],
          ['Owner', 'imageOwnerId'],
          ['Name or Location', '_name_or_location'],
          ['Image Type', '_type'],
          ['Public', 'isPublic']
        ]
        report('AMAZON MACHINE IMAGES', ReportTable.create(report_spec, images))
      end

      desc :instances, 'Describe EC2 server instances'
      def instances
        instances = aws.describe_instances.array('reservationSet item')
        instances = instances.map{ |h| h.array('instancesSet item') }.flatten
        instances.each do |i|
          if i['tagSet']
            name_tag = i['tagSet']['item'].detect{ |h| h['key'] == 'Name' }
            i['_name'] = name_tag['value'] if name_tag
          end
        end
        report_spec = [
          ['Name', '_name'],
          ['IP Address', 'ipAddress'],
          ['Instance ID', 'instanceId'],
          ['Image ID', 'imageId'],
          ['Instance Type', 'instanceType'],
          ['Availability Zone', 'placement availabilityZone'],
          ['State', 'instanceState name']
        ]
        report("EC2 INSTANCES", ReportTable.create(report_spec, instances))
      end

      desc :volumes, 'Describe Elastic Block Store (EBS) volumes'
      def volumes
        volumes = aws.describe_volumes.array('volumeSet item')
        volumes.each do |vol|
          vol['_instance_id'] = vol.first_hash('attachmentSet item').string('instanceId')
        end
        spec = [
          ['Volume ID', 'volumeId'],
          ['Size', 'size'],
          ['Status', 'status'],
          ['Zone', 'availabilityZone'],
          ['Snapshot ID', 'snapshotId'],
          ['Used by', '_instance_id']
        ]
        report("EBS VOLUMES", ReportTable.create(spec, volumes))
      end

    end
  end
end
