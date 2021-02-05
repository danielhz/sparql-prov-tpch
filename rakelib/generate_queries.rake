require 'fileutils'

HOME = File.dirname(File.join(__dir__))
DBGEN_DIR = File.join(HOME, 'tpc-h-tool/2.18.0_rc2/dbgen')
DSS_QUERY = File.join(HOME, 'query_parameter_templates')
QGEN = "#{DBGEN_DIR}/qgen"

parameter_tasks = []
query_tasks = []

%w[01 03 05 06 07 08 09 10 12 14 19].each do |query|
  Dir['datasets/ds_ttl_*'].sort.each do |dataset|
    scale_factor = dataset.sub('datasets/ds_ttl_', '')
    params_file = File.join('query_parameters',
                            "q#{query}_s#{scale_factor.sub('.', 'd')}.rb")
    params_task = "params_#{query}_#{scale_factor}"
    parameter_tasks.append(params_task)

    desc "Generate parameters for query=#{query}, scale factor=#{scale_factor}"
    task params_task => params_file

    file params_file do
      FileUtils.mkdir_p(File.dirname(params_file))
      sh "echo 'PARAMS = [' > #{params_file}"
      (1..20).each do |j|
        sh "DSS_CONFIG=#{DBGEN_DIR} DSS_QUERY=#{DSS_QUERY} " \
           "#{QGEN} -r #{j} -s #{scale_factor} #{query} | " \
           "sed --expression='s/^--/  #/g' >> #{params_file}"
      end
      sh "echo ']' >> #{params_file}"
    end

    %w[base prov_naryrel base_non_aggregate prov_naryrel_non_aggregate
       construct_base
       construct_prov_naryrel
       construct_base_non_aggregate
       construct_prov_naryrel_non_aggregate].each do |mode|
      (1..10).each do |j|
        query_file = File.join('queries',
                               query, mode, scale_factor.sub('.', 'd'),
                               format('q%03d.sparql', j))

        query_task = :"query_#{query}_#{scale_factor}_#{mode}_#{'%03d' % j}"
        query_tasks.append(query_task)

        desc "Generate query=#{query}, mode=#{mode}, scale factor=#{scale_factor}"
        task query_task => query_file

        query_generator = File.join('query_generators', "#{query}.rb")
        query_example = File.join('sparql_examples',
                                  "#{query}_#{mode}.sparql")

        file query_file => [params_file, query_example, query_generator] do
          FileUtils.mkdir_p(File.dirname(query_file))
          sh "#{query_generator} #{mode} #{scale_factor.sub('.', 'd')} #{j} " \
             "> #{query_file}"
        end
      end
    end
  end
end

desc 'Generate query parameters'
task :parameters => parameter_tasks

desc 'Generate queries'
task :queries => query_tasks
