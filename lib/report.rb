require 'csv'

class Report
  attr :file
  def initialize(file)
    @file = file
  end

  def to_hash
    @hash = begin
      hash = {}
      CSV.open(file) do |csv|
        csv.each do |row|
          label = row.shift
          hash[label] = row
        end
      end
      hash
    end
  end

  def compare(report)
    us = to_hash
    them = report.to_hash
    common_labels = us.keys & them.keys
    my_labels = us.keys - common_labels
    their_labels = them.keys - common_labels
    results = common_labels.map do |label|
      my_time = us[label].first.to_f
      their_time = them[label].first.to_f
      [label, my_time, their_time, their_time / my_time]
    end
    results += my_labels.map do |label|
      my_time = us[label].first.to_f
      [label, my_time, nil, nil]
    end
    results += their_labels.map do |label|
      their_time = them[label].first.to_f
      [label, nil, their_time, nil]
    end
    results
  end
end

