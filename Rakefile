#Rake.application.options.trace_rules = true

require 'sequel'
require 'dotenv'
require 'csv'
require 'conceptql/query'
require 'rake/clean'

SOURCE_FILES = Rake::FileList.new('statements/**/*.rb')

SQL_FILES = SOURCE_FILES.pathmap('%{^statements/,tmp/sql/}X.sql')
CLEAN.include(SQL_FILES)

RESULT_FILES = SOURCE_FILES.pathmap('%{^statements/,validation_results/}X.csv')
RESULT_FILES.exclude do |f|
  `git ls-files #{f}`.present?
end

LOAD_INDICATION_FILES = SOURCE_FILES.pathmap('%{^statements/,tmp/validation_results/}X.loaded')
CLOBBER.include(LOAD_INDICATION_FILES)

VALIDATION_TEST_FILES = SOURCE_FILES.pathmap('%{^statements/,tmp/validation_tests/}d.pg')
CLOBBER.include(VALIDATION_TEST_FILES)


task default: :test

task :environment do
  Dotenv.load
end

rule '.sql' => [->(f) { rb_for_sql(f) }] do |t|
  query = cql_query(t.source)
  all_paths = paths(t.source)
  schema_name = all_paths.first
  results_query = db.from(validation_results_table_name(schema_name))
  output = ["SET search_path TO #{all_paths.join(',')};"]
  output << db.select(Sequel.function(:results_eq, query.sql, results_query.sql, db.literal(schema_name.to_s))).sql + ';'
  mkdir_p t.name.pathmap('%d')
  File.write(t.name, output.join("\n"));
end

rule '.csv' => [->(f) { rb_for_csv(f) }] do |t|
  mkdir_p t.name.pathmap('%d')
  CSV.open(t.name, 'w') do |csv|
    cql_query(t.source).each do |row|
      csv << row.values
    end
  end
end

rule '.loaded' => [->(f) { csv_for_loaded(f) }] do |t|
  schema_name = schemas(t.source.pathmap('%{^tmp/validation_results/,statements/}p')).first
  create_schema(schema_name)
  create_validation_results_table(schema_name)
  File.open(t.source) do |csv|
    db.copy_into(validation_results_table_name(schema_name), format: :csv, data: csv.read)
  end
  mkdir_p t.name.pathmap('%d')
  touch t.name
end

SQL_FILES.pathmap('%d').uniq.each do |dir|
  pg_file = dir.pathmap('%{^tmp/sql/,tmp/validation_tests/}p.pg')
  sql_files = SQL_FILES.select { |p| p.match(dir) }

  file pg_file => sql_files do
    mkdir_p pg_file.pathmap('%d')
    File.open(pg_file, 'w') do |f|
      f.puts "select plan(#{sql_files.length});"
      sql_files.each do |sql_file|
        f.puts File.read(sql_file)
      end
      f.puts "select * from finish();"
    end
  end
end

task test: ['validation:test']

namespace :validation do
  task load_results: RESULT_FILES + LOAD_INDICATION_FILES
  task :mark_unloaded do
    rm_rf Rake::FileList.new('tmp/validation_results/**/*.loaded')
  end
  task reload_results: [:mark_unloaded, :load_results]
  task test: [:environment, :load_results] + VALIDATION_TEST_FILES do
    sh "pg_prove -d #{ENV['DBNAME']} -r tmp/validation_tests"
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

def validation_results_table_name(schema_name)
  "#{schema_name}__validation_results".to_sym
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

def create_validation_results_table(schema_name)
  db.create_table!(validation_results_table_name(schema_name)) do
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
  SOURCE_FILES.detect { |f| f.ext('') == csv_file.pathmap('%{^tmp/validation_results/,statements/}X') }
end

def rb_for_sql(sql_file)
  SOURCE_FILES.detect { |f| f.ext('') == sql_file.pathmap('%{^tmp/sql/,statements/}X') }
end
