Rake.application.options.trace_rules = true

require 'benchmark'
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

VALIDATION_RESULT_FILES = VALIDATION_STATEMENT_FILES.pathmap('%{^statements*/,validation_results/}X/v_results.csv')
VALIDATION_RESULT_FILES.exclude do |f|
  !(`git ls-files #{f}`).empty?
end

BENCHMARK_RESULT_FILES = BENCHMARK_STATEMENT_FILES.pathmap('%{^statements*/,benchmark_results/}X.csv')
CLOBBER.include(BENCHMARK_RESULT_FILES)

VALIDATION_LOAD_INDICATION_FILES = VALIDATION_STATEMENT_FILES.pathmap('%{^statements*/,tmp/validation_results/}X/v_results.loaded')
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
  #output << %Q{db.execute("SET search_path TO #{all_paths.join(',')}")}
  output << %Q{set_eq(ordered_cql_query('#{t.source}'), db.from(%q{#{vh.results_table_name(schema_name)}}.to_sym), %q{#{t.source.pathmap('%-1d/%n')}})}
  #output << %Q{set_eq(db[%q{#{query.sql}}], db[%q{#{results_query.sql}}], %q{#{t.source.pathmap('%-1d/%n')}})}
  mkdir_p t.name.pathmap('%d')
  File.write(t.name, output.join("\n"));
end

# This rule takes a benchmark ConceptQL statement and creates a snippet of SQL to run
# the query in a "performs_within" pgTAP test
rule(/(benchmark.+)\.sql/ => [->(f) { bh.rb_for_sql(f) }]) do |t|
  desired_average = bh.desired_average_for(t.source)
  standard_deviation = [bh.standard_deviation_for(t.source) * 2, desired_average / 10].max
  #output = [%Q{db.execute("SET search_path TO #{bh.paths(t.source).join(',')}");}]
  output << %Q{performs_within(cql_query('#{t.source}'), #{desired_average}, #{standard_deviation}, '#{t.source.pathmap('%-1d/%n')}')}
  mkdir_p t.name.pathmap('%d')
  File.write(t.name, output.join("\n"));
end

# This rule takes a validation ConceptQL statement and turns it into SQL
# and records the results from that SQL in a CSV file
rule(/(validation.+)\.csv$/ => [->(f) { vh.rb_for_csv(f) }]) do |t|
  mkdir_p t.name.pathmap('%d')
  #db.execute("SET search_path TO #{vh.paths(t.source).join(',')};")
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
  iterations = 10
  puts "Creating benchmarks for #{t.name}"
  #db.execute("SET search_path TO #{bh.paths(t.source).join(',')};")
  query = cql_query(t.source)
  elapsed = Benchmark.realtime do
    iterations.times do
      query.count
    end
  end
  avg = elapsed.to_f / iterations
  puts "#{avg} average time elapsed"
  CSV.open(t.name, 'w') do |csv|
    csv << [avg, avg / 3]
  end
end

# This rule checks to make sure the CSV file for a validation test's results
# has been loaded into the database
rule(/(validation.+)\.loaded$/ => [->(f) { vh.csv_for_loaded(f) }]) do |t|
  schema_name = vh.schemas(t.source.pathmap('%{^validation_results/,statements/}p')).first
  create_schema(schema_name)
  vh.create_results_table(schema_name)
  copy_into(vh.results_table_name(schema_name), t.source)
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
    sh "bundle exec dbtap run_test #{Rake::FileList.new('tmp/validation_tests/*.pg')}"
  end

  desc 'removes all validation schemas from the database'
  task clobber_db: [:environment, :mark_unloaded] do
    drop_schemas_like(/^_pgt_v/)
  end
end

task benchmark: 'benchmark:test'
namespace :benchmark do
  desc 'run the benchmark tests'
  task test: [:environment] + BENCHMARK_RESULT_FILES + BENCHMARK_TEST_FILES do
    sh "bundle exec dbtap run_test #{Rake::FileList.new('tmp/benchmark_tests/*.pg')}"
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

namespace :vocab do
  task load: [:environment] do
    vh.vocab
  end
end

namespace :db do
  namespace :clobber do
    task schemas: [:environment, 'validate:mark_unloaded'] do
      drop_schemas_like(/^_pgt/)
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
def set_path(schema)
  db.run("USE #{schema};")
end

def dump_using_schema_path(path)
  #db.execute("SET search_path TO #{path}")
  db.extension :schema_dumper
  puts db.dump_schema_migration
end

def create_schema(name)
  db.create_schema(name)
rescue Sequel::DatabaseError
  raise unless $!.message =~ /DuplicateSchema/ || $!.message =~ /Database already exists/
#rescue PG::DuplicateSchema
  # This is fine with me.  Do nothing
end

def drop_schemas_like(schema_pattern)
  db.fetch('SHOW DATABASES;').each do |db_entry|
    schema = db_entry[:name]
    next unless schema =~ schema_pattern
    begin
      drop_schema(schema)
    rescue Sequel::DatabaseError
      raise unless $!.message =~ /InvalidSchemaName/
    #rescue PG::InvalidSchemaName
      # This is fine with me.  Do nothing
    end
  end
end

def drop_schema(schema)
  set_path(schema)
  db.tables.each do |table|
    db.drop_table(table, if_exists: true)
  end
  set_path(:default)
  db.drop_schema(schema, if_exists: true)
end

def make_pg_tap_test_file(pg_file, sql_files)
  mkdir_p pg_file.pathmap('%d')
  path = Pathname.pwd
  File.open(pg_file, 'w') do |f|
    f.puts "define_tests do"
    f.puts "require '#{path.expand_path + 'lib' + 'conceptqlizer'}'"
    f.puts "self.class.send(:include, ConceptQLizer)"
    f.puts "db.execute('use _validation1;')"
    f.puts "db.extension :error_sql"
    f.puts "begin"
    sql_files.each do |sql_file|
      f.puts File.read(sql_file)
    end
    f.puts "rescue"
    f.puts 'puts "Error in #{sql_file}:"'
    f.puts "puts $!.message"
    f.puts "puts $!.sql if $!.respond_to?(:sql)"
    f.puts "raise $!"
    f.puts "end"
    f.puts "end"
  end
end

def vh
  @vh ||= ValidationHelper.new
end

def bh
  @bh ||= BenchmarkHelper.new
end

def copy_into(table, csv_file)
  #db.extend Sequel::CsvToParquet
  db.extension :csv_to_parquet
  db.load_csv(csv_file, table.to_sym, empty_null: :ruby)
=begin
  headers = CSV.parse(File.open(csv_file, &:readline)).first.map(&:downcase).map(&:to_sym)

  puts `wc -l #{csv_file}`
  csv_file.gsub!(%r|^/tmp|, '/user/cloudera')
  csv_file.gsub!(%r|^/home/cloudera|, '/user/cloudera')
  csv_file.gsub!(%r|^validation_results|, '/user/cloudera/validation_results')
  csv_file.gsub!(/^/, '/user/cloudera/sample_validation_data/') if csv_file !~ %r|^/|
  if csv_file =~ /cleaned/
    csv_file.gsub!(/cleaned/, 'split')
    csv_file.gsub!(/\.csv$/, '')
  end
  csv_file.gsub!(%r|/v_results.csv$|, '')
  puts csv_file

  db.create_schema(:copy_staging, if_not_exists: true)
  sch = Hash[db.schema(table)]
  staging_table = table.to_s.split('__').last
  staging_table = ("copy_staging__" + staging_table).to_sym
  db.create_table!(staging_table, location: csv_file, field_term: ",", line_term: "\n", table_properties: '"skip.header.line.count"="1"') do |gen|
    headers.each do |header|
      orig_opts = sch[header]
      #puts header
      #puts orig_opts
      type = orig_opts[:type]
      #puts type
      type_klass = [db.schema_type_class(type)].flatten.last
      #puts type_klass.inspect
      opts = {}
      case type
      when :string
        if orig_opts[:column_size] < 10
          opts.merge!(size: orig_opts[:column_size], fixed: true)
        end
      end
      #puts opts.inspect
      #send(sch[header][:type], header)
      gen.column(header, type_klass, opts)
    end
  end

  #db.load_data(csv_file, staging_table, overwrite: true)

  puts "staging_table #{db[staging_table].count} #{db[staging_table].limit(5).all}"

  db[table].insert(headers, db[staging_table])
=end

=begin
  puts db["LOAD DATA INPATH ? OVERWRITE INTO TABLE ?", csv_file, table].sql
  db["LOAD DATA INPATH ? OVERWRITE INTO TABLE ?", csv_file, table].all
  table_specs = db.schema(table.to_sym)
  types = table_specs.each_with_object({}) do |spec, hash|
    hash[spec.first] = spec.last[:type]
  end
  csv = CSV.read(csv_file, headers: true)
  rows = []
  puts types
  puts csv.headers
  csv.each do |row|
    r = []
    csv.headers.each do |header|
      case types[header.downcase.to_sym]
      when :integer
        r << (row[header].nil? ? nil : row[header].to_i)
      when :float, :double
        r << (row[header].nil? ? nil : row[header].to_f)
      when :string, :timestamp, :datetime
        r << (row[header].nil? ? nil : row[header])
      else
        raise "fail: #{header}: #{types[header.downcase.to_sym.inspect]}"
      end
    end
    rows << r
  end
  puts "Data prepped, issuing import command of #{rows.length} rows"
  db[table].import(csv.headers, rows)
=end
end

class MyHelper
  def vocab
    db.create_schema(:vocabulary, if_not_exists: true)
    Creator.new.create_vocab_tables(:vocabulary)
    load_vocabs
  end

  def load_vocabs
    %w(concept concept_ancestor concept_relationship concept_synonym relationship source_to_concept_map vocabulary).each do |fname|
      copy_into("vocabulary__#{fname}".to_sym, "/home/cloudera/omop_vocab_4.3/cleaned/#{fname}.csv")
    end
  end

  def reload_data
    reload_schema
    import_data
    add_indexes
  end

  def reload_schema
    destroy_schema
    load_schema
  end

  def destroy_schema
    puts "Completely destroying and rebuilding #{ENV['DBNAME']}'s #{dbschema}"
    drop_schemas_like(Regexp.new(dbschema))
    create_schema(dbschema)
  end

  def load_schema
    set_path(dbschema)
    Creator.new.create_tables(dbschema)
  end

  def import_data
    Dir.chdir(data_dir) do
      %w(person visit_occurrence condition_occurrence procedure_occurrence death).each do |table|
        file_name = table + '.csv'
        table_name = "#{dbschema}__#{table}".to_sym
        puts "Importing into #{table_name}"
        copy_into(table_name, file_name)
      end
    end
  end

  def add_indexes
    #db.execute("SET search_path TO #{dbschema}")
    #Sequel.extension :migration
    #Sequel::Migrator.run(db, 'schemas', target: 2)
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
    set_path(dbschema)
    begin
      db[:death].count == expected_death_count
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
      Bignum :criterion_id
      String :criterion_type
      DateTime   :start_date
      DateTime   :end_date
      Bignum :value_as_numeric
      String :value_as_string
      Bignum :value_as_concept_id
    end
  end

  def csv_for_loaded(loaded_file)
    loaded_file.pathmap('%{^tmp/,}X.csv')
  end

  def rb_for_csv(csv_file)
    VALIDATION_STATEMENT_FILES.detect { |f| f.pathmap('%X') == csv_file.pathmap('%{^validation_results/,statements/}d') } ||
    VALIDATION_STATEMENT_FILES.detect { |f| f.pathmap('%X') == csv_file.pathmap('%{^validation_results/,statements_for_validation/}d') }
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

    schemas.reverse.map { |w| truncate('_pgt' + w) }
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

class Creator

  def create_table(name, opts = {}, &block)
    opts = {
      parquet: true,
    }.merge(opts)
    db.create_table!(table_name(name), opts, &block)
  end

  def table_name(name)
    name
  end

  def create_tables(schema)
    db.execute("USE #{schema};")
    location_table = table_name(:location)
    provider_table = table_name(:provider)
    person_table = table_name(:person)
    drug_exposure_table = table_name(:drug_exposure)
    procedure_occurrence_table = table_name(:procedure_occurrence)
    create_table(table_name(:care_site), :ignore_index_errors=>true) do
      Bignum :care_site_id
      Bignum :location_id
      Bignum :organization_id
      Bignum :place_of_service_concept_id
      String :care_site_source_value
      String :place_of_service_source_value
    end

    create_table(table_name(:cohort), :ignore_index_errors=>true) do
      Bignum :cohort_id
      Bignum :cohort_concept_id
      DateTime :cohort_start_date
      DateTime :cohort_end_date
      Bignum :subject_id
      String :stop_reason
    end

    create_table(table_name(:location), :ignore_index_errors=>true) do
      Bignum :location_id
      String :address_1
      String :address_2
      String :city
      String :state
      String :zip
      String :county
      String :location_source_value
    end

    create_table(table_name(:provider), :ignore_index_errors=>true) do
      Bignum :provider_id
      String :npi
      String :dea
      Bignum :specialty_concept_id
      Bignum :care_site_id
      String :provider_source_value
      String :specialty_source_value
    end

    create_table(table_name(:organization), :ignore_index_errors=>true) do
      Bignum :organization_id
      Bignum :place_of_service_concept_id
      Bignum :location_id
      String :organization_source_value
      String :place_of_service_source_value
    end

    create_table(table_name(:person), :ignore_index_errors=>true) do
      Bignum :person_id
      Bignum :gender_concept_id
      Integer :year_of_birth
      Integer :month_of_birth
      Integer :day_of_birth
      Bignum :race_concept_id
      Bignum :ethnicity_concept_id
      Bignum :location_id
      Bignum :provider_id
      Bignum :care_site_id
      String :person_source_value
      String :gender_source_value
      String :race_source_value
      String :ethnicity_source_value
    end

    create_table(table_name(:condition_era), :ignore_index_errors=>true) do
      Bignum :condition_era_id
      Bignum :person_id
      Bignum :condition_concept_id
      DateTime :condition_era_start_date
      DateTime :condition_era_end_date
      Bignum :condition_type_concept_id
      Integer :condition_occurrence_count

    end

    create_table(table_name(:condition_occurrence), :ignore_index_errors=>true) do
      Bignum :condition_occurrence_id
      Bignum :person_id
      Bignum :condition_concept_id
      DateTime :condition_start_date
      DateTime :condition_end_date
      Bignum :condition_type_concept_id
      String :stop_reason
      Bignum :associated_provider_id
      Bignum :visit_occurrence_id
      String :condition_source_value

    end

    create_table(table_name(:death), :ignore_index_errors=>true) do
      Bignum :person_id
      DateTime :death_date
      Bignum :death_type_concept_id
      Bignum :cause_of_death_concept_id
      String :cause_of_death_source_value

    end

    create_table(table_name(:drug_era), :ignore_index_errors=>true) do
      Bignum :drug_era_id
      Bignum :person_id
      Bignum :drug_concept_id
      DateTime :drug_era_start_date
      DateTime :drug_era_end_date
      Bignum :drug_type_concept_id
      Integer :drug_exposure_count

    end

    create_table(table_name(:drug_exposure), :ignore_index_errors=>true) do
      Bignum :drug_exposure_id
      Bignum :person_id
      Bignum :drug_concept_id
      DateTime :drug_exposure_start_date
      DateTime :drug_exposure_end_date
      Bignum :drug_type_concept_id
      String :stop_reason
      Integer :refills
      Integer :quantity
      Integer :days_supply
      String :sig
      Bignum :prescribing_provider_id
      Bignum :visit_occurrence_id
      Bignum :relevant_condition_concept_id
      String :drug_source_value

    end

    create_table(table_name(:observation), :ignore_index_errors=>true) do
      Bignum :observation_id
      Bignum :person_id
      Bignum :observation_concept_id
      DateTime :observation_date
      DateTime :observation_time
      Float :value_as_number
      String :value_as_string
      Bignum :value_as_concept_id
      Bignum :unit_concept_id
      Float :range_low
      Float :range_high
      Bignum :observation_type_concept_id
      Bignum :associated_provider_id
      Bignum :visit_occurrence_id
      Bignum :relevant_condition_concept_id
      String :observation_source_value
      String :units_source_value

    end

    create_table(table_name(:observation_period), :ignore_index_errors=>true) do
      Bignum :observation_period_id
      Bignum :person_id
      DateTime :observation_period_start_date
      DateTime :observation_period_end_date
      DateTime :prev_ds_period_end_date

    end

    create_table(table_name(:payer_plan_period), :ignore_index_errors=>true) do
      Bignum :payer_plan_period_id
      Bignum :person_id
      DateTime :payer_plan_period_start_date
      DateTime :payer_plan_period_end_date
      String :payer_source_value
      String :plan_source_value
      String :family_source_value
      DateTime :prev_ds_period_end_date

    end

    create_table(table_name(:procedure_occurrence), :ignore_index_errors=>true) do
      Bignum :procedure_occurrence_id
      Bignum :person_id
      Bignum :procedure_concept_id
      DateTime :procedure_date
      Bignum :procedure_type_concept_id
      Bignum :associated_provider_id
      Bignum :visit_occurrence_id
      Bignum :relevant_condition_concept_id
      String :procedure_source_value

    end

    create_table(table_name(:visit_occurrence), :ignore_index_errors=>true) do
      Bignum :visit_occurrence_id
      Bignum :person_id
      DateTime :visit_start_date
      DateTime :visit_end_date
      Bignum :place_of_service_concept_id
      Bignum :care_site_id
      String :place_of_service_source_value

    end

    create_table(table_name(:drug_cost), :ignore_index_errors=>true) do
      Bignum :drug_cost_id
      Bignum :drug_exposure_id
      Float :paid_copay
      Float :paid_coinsurance
      Float :paid_toward_deductible
      Float :paid_by_payer
      Float :paid_by_coordination_benefits
      Float :total_out_of_pocket
      Float :total_paid
      Float :ingredient_cost
      Float :dispensing_fee
      Float :average_wholesale_price
      Bignum :payer_plan_period_id

    end

    create_table(table_name(:procedure_cost), :ignore_index_errors=>true) do
      Bignum :procedure_cost_id
      Bignum :procedure_occurrence_id
      Float :paid_copay
      Float :paid_coinsurance
      Float :paid_toward_deductible
      Float :paid_by_payer
      Float :paid_by_coordination_benefits
      Float :total_out_of_pocket
      Float :total_paid
      Bignum :disease_class_concept_id
      Bignum :revenue_code_concept_id
      Bignum :payer_plan_period_id
      String :disease_class_source_value
      String :revenue_code_source_value

    end
  end


  def create_vocab_tables(schema)
    db.run("USE #{schema};")
    create_table(table_name(:concept), if_not_exists: true) do
      Bignum :concept_id, :null=>false
      String :concept_name, :null=>false
      Bignum :concept_level, :null=>false
      String :concept_class, :null=>false
      Bignum :vocabulary_id, :null=>false
      String :concept_code, :null=>false
      Date :valid_start_date, :null=>false
      Date :valid_end_date, :null=>false
      String :invalid_reason, :size=>1, :fixed=>true

    end

    create_table(table_name(:concept_ancestor), if_not_exists: true) do
      Bignum :ancestor_concept_id, :null=>false
      Bignum :descendant_concept_id, :null=>false
      Bignum :min_levels_of_separation
      Bignum :max_levels_of_separation

    end

    create_table(table_name(:concept_relationship), if_not_exists: true) do
      Bignum :concept_id_1, :null=>false
      Bignum :concept_id_2, :null=>false
      Bignum :relationship_id, :null=>false
      Date :valid_start_date, :null=>false
      Date :valid_end_date, :null=>false
      String :invalid_reason, :size=>1, :fixed=>true

    end

    create_table(table_name(:concept_synonym), if_not_exists: true) do
      Bignum :concept_synonym_id, :null=>false
      Bignum :concept_id, :null=>false
      String :concept_synonym_name, :null=>false

    end

    create_table(table_name(:drug_approval), if_not_exists: true) do
      Bignum :ingredient_concept_id, :null => false
      Date :approval_date, :null => false
      String :approved_by, :null => false
    end

    create_table(table_name(:drug_strength), if_not_exists: true) do
      Bignum :drug_concept_id, :null => false
      Bignum :ingredient_concept_id, :null => false
      BigDecimal :amount_value
      String :amount_unit
      BigDecimal :concentration_value
      String :concentration_enum_unit
      String :concentration_denom_unit
      Date :valid_start_date, :null => false
      Date :valid_end_date, :null => false
      String :invalid_reason
    end

    create_table(table_name(:relationship), if_not_exists: true) do
      Bignum :relationship_id, :null=>false
      String :relationship_name, :null=>false
      String :is_hierarchical, :size=>1, :fixed=>true
      String :defines_ancestry, :size=>1, :fixed=>true
      Bignum :reverse_relationship

    end

    create_table(table_name(:source_to_concept_map), if_not_exists: true) do
      String :source_code, :null=>false
      Bignum :source_vocabulary_id, :null=>false
      String :source_code_description
      Bignum :target_concept_id, :null=>false
      Bignum :target_vocabulary_id, :null=>false
      String :mapping_type
      String :primary_map, :size=>1, :fixed=>true
      Date :valid_start_date, :null=>false
      Date :valid_end_date, :null=>false
      String :invalid_reason, :size=>1, :fixed=>true

    end

    create_table(table_name(:vocabulary), if_not_exists: true) do
      Bignum :vocabulary_id, :null=>false
      String :vocabulary_name, :null=>false

    end
  end

end
