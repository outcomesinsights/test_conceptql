Rake.application.options.trace_rules = true

require 'sequel'
require 'dotenv'
require 'csv'
require 'conceptql/query'
require 'rake/clean'

STATEMENT_FILES = Rake::FileList.new('statements/**/*.rb')

VALIDATION_SQL_FILES = STATEMENT_FILES.pathmap('%{^statements/,tmp/validation_sql/}X.sql')
CLEAN.include(VALIDATION_SQL_FILES)

BENCHMARK_SQL_FILES = STATEMENT_FILES.pathmap('%{^statements/,tmp/benchmark_sql/}X.sql')
CLEAN.include(BENCHMARK_SQL_FILES)

VALIDATION_RESULT_FILES = STATEMENT_FILES.pathmap('%{^statements/,validation_results/}X.csv')
VALIDATION_RESULT_FILES.exclude do |f|
  `git ls-files #{f}`.present?
end

BENCHMARK_RESULT_FILES = STATEMENT_FILES.pathmap('%{^statements/,benchmark_results/}X.csv')
CLOBBER.include(BENCHMARK_RESULT_FILES)

VALIDATION_LOAD_INDICATION_FILES = STATEMENT_FILES.pathmap('%{^statements/,tmp/validation_results/}X.loaded')
CLOBBER.include(VALIDATION_LOAD_INDICATION_FILES)

VALIDATION_TEST_FILES = STATEMENT_FILES.pathmap('%{^statements/,tmp/validation_tests/}d.pg')
CLOBBER.include(VALIDATION_TEST_FILES)

BENCHMARK_TEST_FILES = STATEMENT_FILES.pathmap('%{^statements/,tmp/benchmark_tests/}d.pg')
CLOBBER.include(BENCHMARK_TEST_FILES)


task default: 'benchmark:test'

task :environment do
  Dotenv.load
end

rule(/(validation.+)\.sql/ => [->(f) { vh.rb_for_sql(f) }]) do |t|
  query = cql_query(t.source)
  all_paths = vh.paths(t.source)
  schema_name = all_paths.first
  results_query = db.from(vh.results_table_name(schema_name))
  output = ["SET search_path TO #{all_paths.join(',')};"]
  output << db.select(Sequel.function(:results_eq, query.sql, results_query.sql, db.literal(t.source.pathmap('%-1d/%n')))).sql + ';'
  mkdir_p t.name.pathmap('%d')
  File.write(t.name, output.join("\n"));
end

rule(/(benchmark.+)\.sql/ => [->(f) { bh.rb_for_sql(f) }]) do |t|
  query = cql_query(t.source)
  desired_average = bh.desired_average_for(t.source)
  standard_deviation = [bh.standard_deviation_for(t.source) * 2, desired_average / 10].max
  output = ["SET search_path TO #{bh.paths(t.source).join(',')};"]
  output << db.select(Sequel.function(:performs_within, query.sql, desired_average, standard_deviation, 10, db.literal(t.source.pathmap('%-1d/%n')))).sql + ';'
  mkdir_p t.name.pathmap('%d')
  File.write(t.name, output.join("\n"));
end

rule(/(validation.+)\.csv$/ => [->(f) { vh.rb_for_csv(f) }]) do |t|
  mkdir_p t.name.pathmap('%d')
  CSV.open(t.name, 'w') do |csv|
    cql_query(t.source).each do |row|
      csv << row.values
    end
  end
end

rule(/(benchmark.+)\.csv$/ => [->(f) { bh.rb_for_csv(f) }]) do |t|
  mkdir_p t.name.pathmap('%d')
  puts "Creating benchmarks for #{t.name}"
  db.execute("SET search_path TO #{bh.paths(t.source).join(',')};")
  rows = db.from(Sequel.function(:_time_trials, cql_query(t.source).sql, 10, 0.8))
           .select(Sequel.function(:avg, :a_time), Sequel.function(:stddev, :a_time)).all
  CSV.open(t.name, 'w') do |csv|
    rows.each do |row|
      csv << row.values
    end
  end
end

rule(/(validation.+)\.loaded$/ => [->(f) { vh.csv_for_loaded(f) }]) do |t|
  schema_name = vh.schemas(t.source.pathmap('%{^tmp/validation_results/,statements/}p')).first
  create_schema(schema_name)
  vh.create_results_table(schema_name)
  File.open(t.source) do |csv|
    db.copy_into(vh.results_table_name(schema_name), format: :csv, data: csv.read)
  end
  mkdir_p t.name.pathmap('%d')
  touch t.name
end

BENCHMARK_SQL_FILES.pathmap('%d').uniq.each do |dir|
  pg_file = dir.pathmap('%{^tmp/benchmark_sql/,tmp/benchmark_tests/}p.pg')
  sql_files = BENCHMARK_SQL_FILES.select { |p| p.match(dir) }

  file pg_file => sql_files do
    make_pg_tap_test_file(pg_file, sql_files)
  end
end

VALIDATION_SQL_FILES.pathmap('%d').uniq.each do |dir|
  pg_file = dir.pathmap('%{^tmp/validation_sql/,tmp/validation_tests/}p.pg')
  sql_files = VALIDATION_SQL_FILES.select { |p| p.match(dir) }

  file pg_file => sql_files do
    make_pg_tap_test_file(pg_file, sql_files)
  end
end

task test: [:validate]

task validate: 'validate:test'
namespace :validate do
  task load_results: VALIDATION_RESULT_FILES + VALIDATION_LOAD_INDICATION_FILES

  task :mark_unloaded do
    rm_rf Rake::FileList.new('tmp/validation_results/**/*.loaded')
  end

  task reload_results: [:mark_unloaded, :load_results]

  task test: [:environment, :load_results] + VALIDATION_TEST_FILES do
    sh "pg_prove -d #{ENV['DBNAME']} -r tmp/validation_tests"
  end

  task clobber_db: [:environment, :mark_unloaded] do
    drop_schemas_like('_pg_tap_validation%')
  end
end

namespace :benchmark do
  task test: [:environment] + BENCHMARK_RESULT_FILES + BENCHMARK_TEST_FILES do
    sh "pg_prove -d #{ENV['DBNAME']} -r tmp/benchmark_tests"
  end

  task reload_data: [:environment, :reload_schema, :import_data, :add_indexes]

  task reload_schema: [:destroy_schema, :load_schema, :make_views]

  task destroy_schema: [:destroy_schema, :load_schema] do
    puts "About to completely destroy and rebuild #{ENV['DBNAME']}'s #{bh.dbschema}.  CTRL-C now if this is a Bad Thing."
    $stdin.gets
    drop_schemas_like(bh.dbschema)
    create_schema(bh.dbschema)
  end

  task load_schema: [:environment] do
    db.execute("SET search_path TO #{bh.dbschema}")
    Sequel.extension :migration
    Sequel::Migrator.run(db, 'schemas', target: 1)
  end

  task import_data: [:environment] do
    Dir.chdir(ENV['DATA_DIR']) do
      %w(person visit_occurrence condition_occurrence procedure_occurrence death).each do |table|
        file_name = table + '.csv'
        #table_name = "#{bh.dbschema}__#{table}".to_sym
        table_name = "#{bh.dbschema}.#{table}"
        puts "Importing into #{table_name}"
        command = "COPY #{table_name} FROM '#{File.expand_path(file_name)}' WITH HEADER DELIMITER ',' CSV"
        db.execute(command)
      end
    end
  end

  task add_indexes: [:environment] do
    db.execute("SET search_path TO #{bh.dbschema}")
    Sequel.extension :migration
    Sequel::Migrator.run(db, 'schemas', target: 2)
  end

  task make_views: [:environment] do
    require 'conceptql/view_maker'
    ConceptQL::ViewMaker.make_views(db, bh.dbschema)
  end
end

namespace :db do
  namespace :clobber do
    task schemas: [:environment, 'validate:mark_unloaded'] do
      drop_schemas_like('_pg_tap%')
    end
  end

  namespace :schema do
    task :dump do
      db.extension :schema_dumper
      db.execute('SET search_path TO cdmv2')
      puts db.dump_schema_migration
    end
  end
end

#########################################
# Utility functions
#########################################
def db
  @db ||= begin
    Dotenv.load
    url = "postgres://#{ENV['DBUSER']}:#{ENV['DBPASSWORD']}@#{ENV['DBHOST']}/#{ENV['DBNAME']}"
    Sequel.connect(url)
  end
end

def cql_query(file)
  conceptql_query = ConceptQL::Query.new(db, eval(File.read(file)))
  conceptql_query.query
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
  File.open(pg_file, 'w') do |f|
    f.puts "select plan(#{sql_files.length});"
    sql_files.each do |sql_file|
      f.puts File.read(sql_file)
    end
    f.puts "select * from finish();"
  end
end

def vh
  @vh ||= ValidationHelper.new
end

def bh
  @bh ||= BenchmarkHelper.new
end

class ValidationHelper
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
    STATEMENT_FILES.detect { |f| f.ext('') == csv_file.pathmap('%{^validation_results/,statements/}X') }
  end

  def rb_for_sql(sql_file)
    STATEMENT_FILES.detect { |f| f.ext('') == sql_file.pathmap('%{^tmp/validation_sql/,statements/}X') }
  end

  def schemas(source_file)
    schemas = ['']
    Pathname.new(source_file.pathmap('%{^statements/,validation_results/}X')).each_filename do |part|
      schemas << [schemas.last, part.gsub(/\W/, '_')].join('_')
    end
    schemas.reverse.map { |w| '_pg_tap' + w }
  end

  def paths(source_file)
    path_list = schemas(source_file)
    path_list << 'cdmv2'
    path_list << 'vocabulary'
    path_list << 'public'
  end

  def results_table_name(schema_name)
    "#{schema_name}__validation_results".to_sym
  end
end

class BenchmarkHelper
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
    STATEMENT_FILES.detect { |f| f.ext('') == csv_file.pathmap('%{^benchmark_results/,statements/}X') }
  end

  def rb_for_sql(sql_file)
    puts sql_file
    STATEMENT_FILES.detect { |f| f.ext('') == sql_file.pathmap('%{^tmp/benchmark_sql/,statements/}X') }
  end

  def schemas(source_file)
    schemas = ['']
    Pathname.new(source_file.pathmap('%{^statements/,benchmarks_results/}X')).each_filename do |part|
      schemas << [schemas.last, part.gsub(/\W/, '_')].join('_')
    end
    schemas.reverse.map { |w| '_pg_tap' + w }
  end

  def paths(source_file)
    path_list = schemas(source_file)
    path_list << bh.dbschema
    path_list << 'cdmv2'
    path_list << 'vocabulary'
    path_list << 'public'
  end

  def results_table_name(schema_name)
    "#{schema_name}__benchmarks_results".to_sym
  end

  def dbschema
    @dbschema ||= begin
      raise 'Please specify schema to use for benchmarking in .env using BM_DBSCHEMA' unless ENV['BM_DBSCHEMA']
      ENV['BM_DBSCHEMA']
    end
  end

  def desired_average_for(source)
    CSV.read(source.pathmap('%{^statements/,benchmark_results/}X.csv')).first.first.to_f
  end

  def standard_deviation_for(source)
    CSV.read(source.pathmap('%{^statements/,benchmark_results/}X.csv')).first.last.to_f
  end
end

