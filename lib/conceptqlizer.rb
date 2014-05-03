require 'conceptql/query'
module ConceptQLizer
  def cql_query(file)
    conceptql_query = ConceptQL::Query.new(db, eval(File.read(file)))
    conceptql_query.query
  end
end
