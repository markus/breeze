module Breeze

  class Elb < Veur

    desc 'create LOAD_BALANCER_NAME [CNAME] [DNS_ZONE_ID]', 'Create a new elastic load balancer'
    method_options :dns_ttl => 60
    def create(name, cname=nil, dns_zone_id=nil)
      conf = CONFIGURATION[:elb]
      response = elb.create_load_balancer(conf[:availability_zones], name, conf[:listeners], conf[:options])
      if cname
        thor("dns:record:create #{dns_zone_id} #{cname}. CNAME #{response.body['CreateLoadBalancerResult']['DNSName']} #{options[:dns_ttl]}")
      end
      elb.configure_health_check(name, conf[:health_check])
    end

    desc 'add_instances LOAD_BALANCER_NAME instance_id [instance_id, ...]', 'Add server instances to a load balancer'
    def add_instances(name, *instance_ids)
      elb.register_instances(instance_ids, name)
    end

    desc 'remove_instances LOAD_BALANCER_NAME instance_id [instance_id, ...]', 'Remove server instances from a load balancer'
    def remove_instances(name, *instance_ids)
      elb.deregister_instances(instance_ids, name)
    end

    desc 'destroy LOAD_BALANCER_NAME', 'Destroy an elastic load balancer'
    method_options :force => false
    def destroy(name, cname=nil, dns_zone_id=nil)
      load_balancer = elb.load_balancers.get(name)
      if force_or_accept?("Destroy load balancer #{name}?")
        load_balancer.destroy
        if cname
          thor("dns:record:destroy #{dns_zone_id} #{cname}. CNAME --force")
        end
        load_balancer.reload
      end
    end

  end
end
