require 'csv'
require 'json'

CSV.foreach(ARGV.first) do |row|
  if @headers
    values = row.map { |value| value || '' }
    row_hash = @headers.zip(values).to_h
    ['pieces', 'answerOptions'].each do |collection_field|
      pre_processed = row_hash[collection_field].gsub('|', ',')
      pre_processed.gsub!('True', '"True"')
      pre_processed.gsub!('False', '"False"')
      row_hash[collection_field] = JSON.parse(pre_processed)
    end
    puts row_hash.to_json
  else
    @headers = row
  end
end
