bench_dependencies = []

# %w{fuseki virtuoso}.each do |engine|
%w{virtuoso}.each do |engine|
  Dir['datasets/ds_ttl_*'].sort.each do |dataset|
    scale_factor = dataset.gsub('datasets/ds_ttl_', '').gsub('.', 'd')
    Dir['queries/*'].sort.each do |query_dir|
      template = query_dir.sub('queries/', '')
      Dir[File.join(query_dir, '*')].each do |mode_dir|
        mode = mode_dir.sub("#{query_dir}/", '')
        task_name = "bench_#{scale_factor}_#{template}_#{mode}_#{engine}"
        
        desc "Run bench for scale factor=#{scale_factor} template=#{template}, mode=#{mode}, engine=#{engine}"
        named_task task_name do
          case engine
          when 'fuseki'
            endpoint = LXDFusekiEndpoint.new("tpch-#{scale_factor}-fuseki3-ubuntu2004")
          when 'virtuoso'
            endpoint = LXDVirtuosoEndpoint.new("tpch-#{scale_factor}-virtuoso7-debian9")
          end
          tpch_bench(endpoint, scale_factor, template, mode)
        end

        bench_dependencies.append(task_dependency(task_name))
      end
    end
  end
end

desc 'Run bench'
task :bench => bench_dependencies
