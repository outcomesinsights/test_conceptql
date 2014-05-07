require 'conceptql/query'
module ConceptQLizer
  def cql_query(file, schema = nil)
    db.execute("SET search_path TO #{schema}") if schema
    conceptql_query = ConceptQL::Query.new(db, eval(File.read(file)))
    conceptql_query.query
  end

  def ordered_cql_query(file, schema = nil)
    cql_query(file, schema).order(*_columns)
  end

private
  def _columns
    %w(
      person_id
      condition_occurrence_id
      death_id
      drug_cost_id
      drug_exposure_id
      observation_id
      payer_plan_period_id
      procedure_cost_id
      procedure_occurrence_id
      visit_occurrence_id
      start_date
      end_date
    ).map(&:to_sym)
  end
end
