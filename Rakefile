Rake.application.options.trace_rules = true

require 'csv'
require 'conceptql/query'
require 'rake/clean'
require 'sequelizer'
require_relative 'lib/conceptqlizer'
require_relative 'lib/pbcopeez'

include Sequelizer
include ConceptQLizer
include Pbcopeez

STATEMENT_FILES = Rake::FileList.new('statements/**/*.rb')
BENCHMARK_STATEMENT_FILES = STATEMENT_FILES + Rake::FileList.new('statements_for_benchmark/**/*.rb')
VALIDATION_STATEMENT_FILES = STATEMENT_FILES + Rake::FileList.new('statements_for_validation/**/*.rb')

VALIDATION_SQL_FILES = VALIDATION_STATEMENT_FILES.pathmap('%{^statements*/,tmp/validation_sql/}X.sql')
CLEAN.include(VALIDATION_SQL_FILES)

BENCHMARK_SQL_FILES = BENCHMARK_STATEMENT_FILES.pathmap('%{^statements*/,tmp/benchmark_sql/}X.sql')
CLEAN.include(BENCHMARK_SQL_FILES)

VALIDATION_RESULT_FILES = VALIDATION_STATEMENT_FILES.pathmap('%{^statements*/,validation_results/}X.csv')
VALIDATION_RESULT_FILES.exclude do |f|
  `git ls-files #{f}`.present?
end

BENCHMARK_RESULT_FILES = BENCHMARK_STATEMENT_FILES.pathmap('%{^statements*/,benchmark_results/}X.csv')
CLOBBER.include(BENCHMARK_RESULT_FILES)

VALIDATION_LOAD_INDICATION_FILES = VALIDATION_STATEMENT_FILES.pathmap('%{^statements*/,tmp/validation_results/}X.loaded')
CLOBBER.include(VALIDATION_LOAD_INDICATION_FILES)

VALIDATION_TEST_FILES = VALIDATION_STATEMENT_FILES.pathmap('%{^statements*/,tmp/validation_tests/}d.pg')
CLOBBER.include(VALIDATION_TEST_FILES)

BENCHMARK_TEST_FILES = BENCHMARK_STATEMENT_FILES.pathmap('%{^statements*/,tmp/benchmark_tests/}d.pg')
CLOBBER.include(BENCHMARK_TEST_FILES)


task default: 'test'

task :environment do
  Dotenv.load
end

# This rule takes a validation ConceptQL statement and creates a snippet of SQL to run
# the query in a "results_eq" pgTAP test
rule(/(validation.+)\.sql/ => [->(f) { vh.rb_for_sql(f) }]) do |t|
  #query = ordered_cql_query(t.source)
  all_paths = vh.paths(t.source)
  schema_name = all_paths.first
  #results_query = db.from(vh.results_table_name(schema_name))
  output = []
  output << %Q{db.execute("SET search_path TO #{all_paths.join(',')}")}
  output << %Q{set_eq(ordered_cql_query('#{t.source}'), db.from(%q{#{vh.results_table_name(schema_name)}}.to_sym), %q{#{t.source.pathmap('%-1d/%n')}})}
  #output << %Q{set_eq(db[%q{#{query.sql}}], db[%q{#{results_query.sql}}], %q{#{t.source.pathmap('%-1d/%n')}})}
  mkdir_p t.name.pathmap('%d')
  File.write(t.name, output.join("\n"));
end

# This rule takes a benchmark ConceptQL statement and creates a snippet of SQL to run
# the query in a "performs_within" pgTAP test
rule(/(benchmark.+)\.sql/ => [->(f) { bh.rb_for_sql(f) }]) do |t|
  query = cql_query(t.source)
  desired_average = bh.desired_average_for(t.source)
  standard_deviation = [bh.standard_deviation_for(t.source) * 2, desired_average / 10].max
  output = [%Q{db.execute("SET search_path TO #{bh.paths(t.source).join(',')}");}]
  output << %Q{performs_within(db[%Q{#{query.sql}}, #{desired_average}, #{standard_deviation}, '#{t.source.pathmap('%-1d/%n')}'])}
  mkdir_p t.name.pathmap('%d')
  File.write(t.name, output.join("\n"));
end

# This rule takes a validation ConceptQL statement and turns it into SQL
# and records the results from that SQL in a CSV file
rule(/(validation.+)\.csv$/ => [->(f) { vh.rb_for_csv(f) }]) do |t|
  mkdir_p t.name.pathmap('%d')
  db.execute("SET search_path TO #{vh.paths(t.source).join(',')};")
  rows = ordered_cql_query(t.source).tap {|o| pbcopy(o.sql) }.all
  CSV.open(t.name, 'w') do |csv|
    csv << rows.first.keys unless rows.empty?
    rows.each do |row|
      csv << row.values
    end
  end
end

# This rule takes a benchmark ConceptQL statement and turns it into SQL
# and runs it 10 times to get an average and standard deviation for the execution time
rule(/(benchmark.+)\.csv$/ => [->(f) { bh.rb_for_csv(f) }]) do |t|
  mkdir_p t.name.pathmap('%d')
  puts "Creating benchmarks for #{t.name}"
  db.execute("SET search_path TO #{bh.paths(t.source).join(',')};")
  rows = db.from(Sequel.function(:_time_trials, cql_query(t.source).sql, 10, 0.8))
           .select(Sequel.function(:avg, :a_time), Sequel.function(:stddev, :a_time)).all
  puts rows.first.values
  CSV.open(t.name, 'w') do |csv|
    rows.each do |row|
      csv << row.values
    end
  end
end

# This rule checks to make sure the CSV file for a validation test's results
# has been loaded into the database
rule(/(validation.+)\.loaded$/ => [->(f) { vh.csv_for_loaded(f) }]) do |t|
  schema_name = vh.schemas(t.source.pathmap('%{^validation_results/,statements/}p')).first
  create_schema(schema_name)
  vh.create_results_table(schema_name)
  File.open(t.source) do |csv|
    db.copy_into(vh.results_table_name(schema_name), format: :csv, data: csv, options: 'HEADER')
  end
  mkdir_p t.name.pathmap('%d')
  touch t.name
end

# This loop declares that all *.pg files related to benchmarks
# are dependent upon their appropriate *.sql snippet files
BENCHMARK_SQL_FILES.pathmap('%d').uniq.each do |dir|
  pg_file = dir.pathmap('%{^tmp/benchmark_sql/,tmp/benchmark_tests/}p.pg')
  sql_files = BENCHMARK_SQL_FILES.select { |p| p.match(dir) }

  file pg_file => sql_files do
    make_pg_tap_test_file(pg_file, sql_files)
  end
end

# This loop declares that all *.pg files related to validations
# are dependent upon their appropriate *.sql snippet files
VALIDATION_SQL_FILES.pathmap('%d').uniq.each do |dir|
  pg_file = dir.pathmap('%{^tmp/validation_sql/,tmp/validation_tests/}p.pg')
  sql_files = VALIDATION_SQL_FILES.select { |p| p.match(dir) }

  file pg_file => sql_files do
    make_pg_tap_test_file(pg_file, sql_files)
  end
end

task test: [:validate, :benchmark]

task validate: 'validate:test'
namespace :validate do
  task load_results: VALIDATION_RESULT_FILES + VALIDATION_LOAD_INDICATION_FILES

  task :mark_unloaded do
    rm_rf Rake::FileList.new('tmp/validation_results/**/*.loaded')
  end

  task reload_results: [:mark_unloaded, :load_results]

  desc 'loads validation data into database'
  task load_data: [:environment] do
    vh.load_data
  end

  desc 'destroys validation database and reloads data'
  task reload_data: [:environment] do
    if ENV['OVERRIDE']
      vh.load_data!
    else
      puts 'Please set OVERRIDE so to indicate you know what you are doing'
    end
  end

  desc 'runs pg_prove on validation tests'
  task test: [:environment, :load_results] + VALIDATION_TEST_FILES do
    sh "bundle exec ../dbtap/bin/dbtap run_test #{Rake::FileList.new('tmp/validation_tests/*.pg')}"
  end

  desc 'removes all validation schemas from the database'
  task clobber_db: [:environment, :mark_unloaded] do
    drop_schemas_like('_pgt_v%')
  end
end

task benchmark: 'benchmark:test'
namespace :benchmark do
  desc 'run the benchmark tests'
  task test: [:environment] + BENCHMARK_RESULT_FILES + BENCHMARK_TEST_FILES do
    sh "pg_prove -d #{ENV['DBNAME']} -r tmp/benchmark_tests"
  end

  desc 'loads benchmark data into database'
  task load_data: [:environment] do
    bh.load_data
  end

  desc 'destroys benchmark database and reloads data'
  task reload_data: [:environment] do
    if ENV['OVERRIDE']
      bh.load_data!
    else
      puts 'Please set OVERRIDE so to indicate you know what you are doing'
    end
  end

  task :update, :pattern do |t, args|
    sh "find statements -name '#{args[:pattern]}' -type d | xargs -n 1 -I{} find {} -name '*.rb' | xargs touch"
  end

  desc 'snapshots all current benchmark results into a single file'
  task :report do
    require 'csv'
    mkdir_p 'reports'
    CSV.open("reports/#{Time.now.strftime('%Y-%m-%d-%H-%M-%S')}.csv", 'w') do |csv|
      BENCHMARK_RESULT_FILES.sort.each do |file|
        label = file.pathmap('%-1d - %n')
        CSV.read(file).map { |row| [label] + row.map(&:to_f) }.each do |row|
          csv << row
        end
      end
    end
  end
end

namespace :db do
  namespace :clobber do
    task schemas: [:environment, 'validate:mark_unloaded'] do
      drop_schemas_like('_pgt%')
    end
  end

  namespace :schema do
    task :dump_truven do
      dump_using_schema_path('cdmv2')
    end
    task dump: :environment do
      dump_using_schema_path(bh.dbschema)
    end
  end
end

#########################################
# Utility functions
#########################################

def dump_using_schema_path(path)
  db.execute("SET search_path TO #{path}")
  db.extension :schema_dumper
  puts db.dump_schema_migration
end

def create_schema(name)
  db.execute("CREATE SCHEMA #{name};")
rescue Sequel::DatabaseError
  raise unless $!.message =~ /DuplicateSchema/
rescue PG::DuplicateSchema
  # This is find with me.  Do nothing
end

def drop_schemas_like(schema_pattern)
  db[:information_schema__schemata].where(Sequel.like(:schema_name, schema_pattern)).select_map(:schema_name).each do |schema|
    begin
      db.execute("DROP SCHEMA #{schema} CASCADE")
    rescue Sequel::DatabaseError
      raise unless $!.message =~ /InvalidSchemaName/
    rescue PG::InvalidSchemaName
      # This is find with me.  Do nothing
    end
  end
end

def make_pg_tap_test_file(pg_file, sql_files)
  mkdir_p pg_file.pathmap('%d')
  path = Pathname.pwd
  File.open(pg_file, 'w') do |f|
    f.puts "define_tests do"
    f.puts "require '#{path.expand_path + 'lib' + 'conceptqlizer'}'"
    f.puts "self.class.send(:include, ConceptQLizer)"
    sql_files.each do |sql_file|
      f.puts File.read(sql_file)
    end
    f.puts "end"
  end
end

def vh
  @vh ||= ValidationHelper.new
end

def bh
  @bh ||= BenchmarkHelper.new
end

class MyHelper
  def reload_data
    reload_schema
    import_data
    add_indexes
  end

  def reload_schema
    destroy_schema
    load_schema
    make_views
  end

  def destroy_schema
    puts "Completely destroying and rebuilding #{ENV['DBNAME']}'s #{dbschema}"
    drop_schemas_like(dbschema)
    create_schema(dbschema)
  end

  def load_schema
    db.execute("SET search_path TO #{dbschema}")
    Sequel.extension :migration
    Sequel::Migrator.run(db, 'schemas', target: 1)
  end

  def import_data
    Dir.chdir(data_dir) do
      %w(person visit_occurrence condition_occurrence procedure_occurrence death).each do |table|
        file_name = table + '.csv'
        table_name = "#{dbschema}__#{table}".to_sym
        puts "Importing into #{table_name}"
        File.open(file_name) do |csv|
          db.copy_into(table_name, format: :csv, data: csv, options: 'HEADER')
        end
      end
    end
  end

  def add_indexes
    db.execute("SET search_path TO #{dbschema}")
    Sequel.extension :migration
    Sequel::Migrator.run(db, 'schemas', target: 2)
  end

  def make_views
    require 'conceptql/view_maker'
    ConceptQL::ViewMaker.make_views(db, dbschema)
  end

  def env_or_bust(var_name)
    value = ENV[var_name]
    raise "Please define #{var_name} in .env" unless value
    value
  end

  def truncate(str)
    return str if str.length < 60
    l = str.length
    str[0,30].sub(/_+$/, '') + str[l-30, l]
  end

  def load_data
    load_data! unless data_loaded?
  end

  def data_loaded?
    db.execute("SET search_path TO #{dbschema}")
    begin
      db[:death_with_dates].count == expected_death_count
    rescue Sequel::DatabaseError
      return false if $!.message =~ /UndefinedTable/
      raise
    end
  end

  def load_data!
    reload_data
  end
end

class ValidationHelper < MyHelper
  def create_results_table(schema_name)
    db.create_table!(results_table_name(schema_name)) do
      Bignum :person_id
      Bignum :condition_occurrence_id
      Bignum :death_id
      Bignum :drug_cost_id
      Bignum :drug_exposure_id
      Bignum :observation_id
      Bignum :payer_plan_period_id
      Bignum :procedure_cost_id
      Bignum :procedure_occurrence_id
      Bignum :visit_occurrence_id
      Date   :start_date
      Date   :end_date
    end
  end

  def csv_for_loaded(loaded_file)
    loaded_file.pathmap('%{^tmp/,}X.csv')
  end

  def rb_for_csv(csv_file)
    VALIDATION_STATEMENT_FILES.detect { |f| f.ext('') == csv_file.pathmap('%{^validation_results/,statements/}X') } ||
    VALIDATION_STATEMENT_FILES.detect { |f| f.ext('') == csv_file.pathmap('%{^validation_results/,statements_for_validation/}X') }
  end

  def rb_for_sql(sql_file)
    VALIDATION_STATEMENT_FILES.detect { |f| f.ext('') == sql_file.pathmap('%{^tmp/validation_sql/,statements/}X') } ||
    VALIDATION_STATEMENT_FILES.detect { |f| f.ext('') == sql_file.pathmap('%{^tmp/validation_sql/,statements_for_validation/}X') }
  end

  def schemas(source_file)
    schemas = ['']
    Pathname.new(source_file.pathmap('%{^statements*/,v/}X')).each_filename do |part|
      schemas << [schemas.last, part.gsub(/\W/, '_')].join('_')
    end
    schemas.reverse.map { |w| truncate('_pgt' + w) }.tap { |o| puts o.inspect }
  end

  def paths(source_file)
    path_list = schemas(source_file)
    path_list << dbschema
    path_list << 'vocabulary'
    path_list << 'public'
  end

  def results_table_name(schema_name)
    "#{truncate(schema_name)}__v_results".to_sym
  end

  def dbschema
    @dbschema ||= env_or_bust('VALIDATION_DBSCHEMA')
  end

  def data_dir
    @data_dir ||= env_or_bust('VALIDATION_DATA_DIR')
  end

  def expected_death_count
    1
  end
end

class BenchmarkHelper < MyHelper
  def create_results_table(schema_name)
    db.create_table!(results_table_name(schema_name)) do
      Numeric :average_time
      Numeric :std_deviation
    end
  end

  def csv_for_loaded(loaded_file)
    loaded_file.pathmap('%{^tmp/,}X.csv')
  end

  def rb_for_csv(csv_file)
    BENCHMARK_STATEMENT_FILES.detect { |f| f.ext('') == csv_file.pathmap('%{^benchmark_results/,statements/}X') } ||
    BENCHMARK_STATEMENT_FILES.detect { |f| f.ext('') == csv_file.pathmap('%{^benchmark_results/,statements_for_benchmark/}X') }
  end

  def rb_for_sql(sql_file)
    puts sql_file
    BENCHMARK_STATEMENT_FILES.detect { |f| f.ext('') == sql_file.pathmap('%{^tmp/benchmark_sql/,statements/}X') } ||
    BENCHMARK_STATEMENT_FILES.detect { |f| f.ext('') == sql_file.pathmap('%{^tmp/benchmark_sql/,statements_for_benchmark/}X') }
  end

  def schemas(source_file)
    schemas = ['']
    Pathname.new(source_file.pathmap('%{^statements/,b/}X')).each_filename do |part|
      schemas << [schemas.last, part.gsub(/\W/, '_')].join('_')
    end
    schemas.reverse.map { |w| truncate('_pgt' + w) }
  end

  def paths(source_file)
    path_list = schemas(source_file)
    path_list << bh.dbschema
    path_list << 'vocabulary'
    path_list << 'public'
  end

  def results_table_name(schema_name)
    "#{truncate(schema_name)}__b_results".to_sym
  end

  def dbschema
    @dbschema ||= env_or_bust('BM_DBSCHEMA')
  end

  def data_dir
    @data_dir ||= env_or_bust('BM_DATA_DIR')
  end

  def desired_average_for(source)
    CSV.read(source.pathmap('%{^statements/,benchmark_results/}X.csv')).first.first.to_f
  end

  def standard_deviation_for(source)
    CSV.read(source.pathmap('%{^statements/,benchmark_results/}X.csv')).first.last.to_f
  end

  def expected_death_count
    1863
  end
end

