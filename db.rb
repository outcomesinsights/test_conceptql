require 'thor'
require 'sequel'
require_relative 'lib/db'
require_relative 'lib/conceptqlizer'
require_relative 'lib/pbcopeez'

class MyCLI < Thor
  include DB
  include ConceptQLizer
  include Pbcopeez

  desc 'explain statement', 'Given a ConceptQL statement file, prints out the EXPLAIN for the resulting query'
  def explain(file_path)
    puts _explain(file_path)
  end

  desc 'explain_analyze statement', 'Given a ConceptQL statement file, prints out the EXPLAIN for the resulting query'
  def explain_analyze(file_path)
    puts _explain_analyze(file_path)
  end

  desc 'show statement', 'Given a ConceptQL statement file, prints outl the SQL'
  def show(file_path)
    puts cql_query(file_path).sql
  end

  desc 'count statement [schema]', 'Given a ConceptQL statement file, prints the number of rows that match'
  def count(file_path, schema = nil)
    puts _count(file_path, schema)
  end

  desc 'copy statement', 'Given a ConceptQL statement file, copies the SQL to clipboard via pbcopy'
  def copy(file_path)
    puts pbcopy(cql_query(file_path).sql)
  end

  desc 'try_index file_path, table_name, columns', 'Given an index string from the command line, apply it, and run an explain'
  def try_index(file_path, table_name, *columns)
    table_name = table_name.to_sym
    columns = columns.map(&:to_sym)
    puts "Capturing explain before index change"
    File.write('/tmp/orig.txt', _explain(file_path))
    puts "Adding index #{table_name} => #{columns.join(',')}"
    db.add_index(table_name, columns.map)
    puts "Analyzing table for new stats"
    db.execute("ANALYZE #{table_name.to_s.gsub('__', '.')}")
    puts "Capturing explain before index change"
    File.write('/tmp/new.txt', _explain(file_path))
    system('vimdiff /tmp/{orig,new}.txt')
    puts "Like what you saw?  Type 'keep' to keep the index."
    unless $stdin.gets.chomp.downcase == 'keep'
      puts "Dropping index"
      db.drop_index(table_name, columns)
    end
  end

  desc 'index_all_the_things schema', 'Given the schema, creates and index on all FK columns (columns ending in _id)'
  def index_all_the_things(schema)
    start_time = Time.now
    db.execute("SET search_path TO #{schema}")
    db.tables.each do |table|
      db.schema(table).select { |column_name, column_info| column_name.to_s =~ /(_id|_value)$/ }.each do |column_name, column_info|
        puts "Indexing #{table}'s #{column_name}"
        db.add_index(table, column_name, ignore_errors: true)
      end
    end
    puts "Seems to be indexed already" if Time.now - start_time < 10
  end

private

  def _explain(file_path)
    cql_query(file_path).explain
  end

  def _explain_analyze(file_path)
    cql_query(file_path).analyze
  end

  def _count(file_path, schema = nil)
    cql_query(file_path, schema).count
  end
end

MyCLI.start(ARGV)
