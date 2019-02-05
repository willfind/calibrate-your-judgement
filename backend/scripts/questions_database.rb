require 'json'
require 'csv'

class AddQuestionsToDatabase
  def initialize options
    @filename = options[:filename]
    @questions_database = QuestionsDatabase.new(database_options(options))
  end

  def execute
    @questions = questions_with_ids_loaded_or_generated

    @questions_database.post_questions({ docs: @questions })
    @questions_database.update_number_of_questions_to(@number_of_questions)
  end

  def summary
    @questions_database.summary
  end

  def questions_with_ids_loaded_or_generated
    add_generated_ids_to({ questions: questions_with_ids_from_database, starting_at: @questions_database.get_number_of_questions })
  end

  def questions_with_ids_from_database
    @questions_database.add_ids_to_question_documents(questions_with_type_set)
  end

  def questions_with_type_set
    questions_from_file.map { |question| question['type'] = 'question'; question }
  end

  def questions_from_file
    @questions_database.questions_from(@filename)
  end

  class << self
    def given options
      add_questions_to_database = AddQuestionsToDatabase.new(options)
      add_questions_to_database.execute
      add_questions_to_database.summary
    end
  end

  private
  
  def database_options options
    options.tap { |options| options.delete(:filename) }
  end

  def add_generated_ids_to options
    questions = options[:questions]
    @number_of_questions = options[:starting_at]
    questions.each do |question|
      next if question['_id']
      question['_id'] ||= "#{@number_of_questions}"
      @number_of_questions += 1
    end
    questions
  end

end

class QuestionsDatabase

  def initialize options
    @username = options[:username]
    @password = options[:password]
    @environment = options[:environment]
    @summary = Summary.new
  end

  def summary
    @summary.export
  end

  def questions_from filename
    csv = CSV.new(questions_text_from(filename), :headers => true)
    csv.to_a.map(&:to_hash)
  end

  def update_number_of_questions_to number
    File.write('./views/lib/number_of_questions.js', "module.exports = #{number}")
    push_couchapp
  end

  def get_number_of_questions
    number_of_questions_docs = curl url_for_number_of_questions
    @number_of_questions = number_of_questions_from(JSON.parse(number_of_questions_docs))
  end

  def post_questions questions
    File.open('_questions.json', 'w') { |file| file.puts questions.to_json }
    curl "-X POST -H \"Content-Type: application/json\" #{authenticated_path_to_database}/_bulk_docs -d @_questions.json"
    File.delete('_questions.json')
  end

  def add_ids_to_question_documents question_docs
    with_ids_merged_in({ question_docs: question_docs, document_ids: document_ids_for(question_docs) })
  end

  private

  def push_couchapp
    `couchapp push #{authenticated_path_to_database}`
  end

  def authenticated_path_to_database
    "#{SCHEME}#{@username}:#{@password}\@#{HOST}/#{@environment}"
  end

  def document_ids_for question_docs
    get_ids_by_question_id(question_ids_from(question_docs))
  end

  def with_ids_merged_in options
    question_docs = options[:question_docs]
    document_ids = options[:document_ids]

    question_docs.each do |doc|
      if document_metadata = document_ids[doc['question_id']]
        doc['_id'] = document_metadata['_id']
        doc['_rev'] = document_metadata['_rev']
        @summary.increment_questions_replaced
      else
        @summary.increment_questions_added
      end
    end
    question_docs
  end

  def question_ids_from question_docs
    question_docs.map { |doc| doc['question_id'] }
  end

  def get_ids_by_question_id question_ids
    question_ids_docs = JSON.parse curl(request_for_question_ids(question_ids))
    ids_by_question_id = {}
    question_ids_docs['rows'].each { |row| ids_by_question_id[row['value']['question_id'].to_s] = { '_id' => row['value']['_id'], '_rev' => row['value']['_rev'] } }
    ids_by_question_id
  end

  def request_for_question_ids question_ids
    "#{authenticated_path_to_database}/_design/bloom_filter/_view/by_question_id"
  end

  def curl request
    `curl -g -v #{request}`
  end

  def questions_text_from filename
    without_empty_lines(lines_from(filename)).compact.join
  end

  def lines_from filename
    File.readlines(filename)
  end

  def without_empty_lines lines
    lines.map { |line| next unless not_empty(line); line }
  end

  def not_empty line
    line[/[^,\r\n]/]
  end

  def url_for_number_of_questions
    "#{authenticated_path_to_database}/_design/bloom_filter/_view/number_of_questions"
  end

  def number_of_questions_from docs
    return 0 unless docs['rows'] && docs['rows'][0] && docs['rows'][0]['value']
    docs['rows'][0]['value']
  end
end

class Summary
  def initialize
    @questions_replaced = 0
    @questions_added = 0
  end

  def export
    { questions_added: @questions_added, questions_replaced: @questions_replaced }
  end

  def increment_questions_added
    @questions_added += 1
  end

  def increment_questions_replaced
    @questions_replaced += 1
  end
end
