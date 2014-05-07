require 'conceptql/query'
module ConceptQLizer
  def cql_query(file, schema = nil)
    db.execute("SET search_path TO #{schema}") if schema
    conceptql_query = ConceptQL::Query.new(db, eval(File.read(file)))
    conceptql_query.query
  end
end
