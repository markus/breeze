module Breeze

  class Elasticache < Veur

    desc 'create CLUSTER_NAME', 'Create a new cache cluster'
    method_options CONFIGURATION[:default_elasticache_options]
    def create(name)
      options.update(:id => name)
      # puts "elasticache options: #{options}"
      elasticache.clusters.create(options)
    end

    desc 'destroy CLUSTER_NAME', 'Destroy a cache cluster'
    method_options :force => false
    def destroy(name)
      cluster = elasticache.clusters.get(name)
      if force_or_accept?("Destroy cache cluster #{name}?")
        cluster.destroy
        cluster.reload
      end
    end

  end
end
