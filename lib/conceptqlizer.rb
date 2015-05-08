require 'conceptql/query'
module ConceptQLizer
  def cql_query(file, schema = nil)
    db.extension :error_sql
    begin
      db.execute("SET search_path TO #{schema}") if schema
      conceptql_query = ConceptQL::Query.new(db, eval(File.read(file)))
      conceptql_query.query.from_self.select(*_columns)
    rescue Sequel::DatabaseError, PG::UndefinedColumn
      puts $!.sql
      raise $!
    end
  end

  def ordered_cql_query(file, schema = nil)
    cql_query(file, schema).order(*_order_columns)
  end

private
  def _columns
    %i(
      person_id
      criterion_id
      criterion_type
      start_date
      end_date
    ) +
      [Sequel.as(:value_as_number, :value_as_number)] +
    %i(
      value_as_string
      value_as_concept_id
    )
  end

  def _order_columns
    [:person_id, :criterion_type, :criterion_id, :start_date, :end_date]
  end
end
