require 'csv'
Pathname.glob('validation_results/**/*.csv').each do |file|
  contents = CSV.read(file, headers: true, return_headers: true)
  headers = contents.select{|r| r.header_row?}.first
  next if contents.length == 0
  CSV.open(file, 'w') do |csv|
    csv << (headers << :value_as_numeric << :value_as_string << :value_as_concept_id)
    contents.select{|r| !r.header_row?}.each { |c| csv << (c << nil << nil << nil) }
  end
end

