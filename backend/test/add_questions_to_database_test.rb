require 'minitest/autorun'
require 'flexmock/test_unit'
require './scripts/questions_database'

SCHEME = 'https://'
HOST = 'openphil.cloudant.com'

class TestAddQuestionsToDatabase < Minitest::Test
  include FlexMock::TestCase

  def test_can_add_questions_to_the_database
    questions_database = QuestionsDatabase.new({ username: 'will', password: 'pass', environment: 'bloom_filter' })
    flexmock(QuestionsDatabase).should_receive(:new).with({ username: 'will', password: 'pass', environment: 'bloom_filter' }).and_return(questions_database).once

   initial_questions = [ 
      { 'question_id' => '1', 'question_text' => 'sup?', 'points' => '5' },
      { 'question_id' => '2', 'question_text' => 'how is it going?', 'points' => '10' }
    ]

    flexmock(questions_database).should_receive(:questions_from).with('questions.csv').and_return(initial_questions).once

    questions_with_saved_ids = [ 
      { 'question_id' => '1', 'question_text' => 'sup?', 'points' => '5', '_id' => '34', '_rev' => 'abc', 'type' => 'question' },
      { 'question_id' => '2', 'question_text' => 'how is it going?', 'points' => '10', 'type' => 'question' }
    ]

    flexmock(questions_database).should_receive(:add_ids_to_question_documents).with(initial_questions).and_return(questions_with_saved_ids).once

    flexmock(questions_database).should_receive(:get_number_of_questions).and_return(55).once

    questions_with_generated_ids = [
      { 'question_id' => '1', 'question_text' => 'sup?', 'points' => '5', '_id' => '34', '_rev' => 'abc', 'type' => 'question' },
      { 'question_id' => '2', 'question_text' => 'how is it going?', 'points' => '10', '_id' => '55', 'type' => 'question' }
    ]

    flexmock(questions_database).should_receive(:post_questions).with({ docs: questions_with_generated_ids }).once

    flexmock(questions_database).should_receive(:update_number_of_questions_to).with(56).once

    AddQuestionsToDatabase.given({ username: 'will', password: 'pass', environment: 'bloom_filter', filename: 'questions.csv' })
  end

end

class TestQuestionsDatabase < Minitest::Test
  include FlexMock::TestCase

  def test_can_add_the_retrieved_ids_to_documents_that_should_have_them
    questions_database = QuestionsDatabase.new({ username: 'will', password: 'pass', environment: 'bloom_filter' })

    docs = [
      { "question_id" => '2', "question" => 'sup?' },
      { "question_id" => '3', "question" => "how's it going?" },
      { "question_id" => '4', "question" => "what are you up to?" }
    ]

    command_to_get_ids_by_question_id = 'https://will:pass@openphil.cloudant.com/bloom_filter/_design/bloom_filter/_view/by_question_id'
    response = '{"total_rows":5,"offset":3,"rows":[ {"id":"1","key":2,"value":{"question_id":"2","_id":"1","_rev":"abc"}}, {"id":"2","key":3,"value":{"question_id":"3","_id":"2","_rev":"def"}}, {"id":"5db5fb638d7d08be520da63c0300bcff","key":null,"value":{"_id":"5db5fb638d7d08be520da63c0300bcff","_rev":"2-cf1c1e1efb5594b80b8c8455286ebba6"}} ]}'

    flexmock(questions_database).should_receive(:curl).with(command_to_get_ids_by_question_id).and_return(response).once

    expected_docs = [
      { 'question_id' => '2', 'question' => 'sup?', '_id' => '1', '_rev' => 'abc' },
      { 'question_id' => '3', 'question' => "how's it going?", '_id' => '2', '_rev' => 'def' },
      { 'question_id' => '4', 'question' => 'what are you up to?' }
    ]

    assert_equal expected_docs, questions_database.add_ids_to_question_documents(docs)
  end

  def test_can_get_the_number_of_questions_in_the_database
    questions_database = QuestionsDatabase.new({ username: 'will', password: 'pass', environment: 'bloom_filter' })

    command_to_get_number_of_questions = "https://will:pass@openphil.cloudant.com/bloom_filter/_design/bloom_filter/_view/number_of_questions"

    response = '{"rows":[ {"key":null,"value":10} ]}'

    flexmock(questions_database).should_receive(:curl).with(command_to_get_number_of_questions).and_return(response).once

    assert_equal 10, questions_database.get_number_of_questions
  end

  def test_can_load_questions_from_a_csv_file
    questions_database = QuestionsDatabase.new({ username: 'will', password: 'pass', environment: 'bloom_filter' })

    lines = ["question_id,question_text,points\n","1,sup?,5\n","2,how is it going?,10\n"]
    flexmock(File).should_receive(:readlines).with('questions.csv').and_return(lines).once

    expected_questions = [
      { 'question_id' => '1', 'question_text' => 'sup?', 'points' => '5' },
      { 'question_id' => '2', 'question_text' => 'how is it going?', 'points' => '10' }
    ]

    assert_equal expected_questions, questions_database.questions_from('questions.csv')
  end

  def test_can_send_questions_to_the_database
    questions_database = QuestionsDatabase.new({ username: 'will', password: 'pass', environment: 'bloom_filter' })

    question_docs = { docs: [
      { 'question_id' => '1', 'question_text' => 'sup?', '_id' => '84' },
      { 'question_id' => '2', 'question_text' => 'ayyy', '_id' => '85' }
    ]}

    file = flexmock('tempfile')
    flexmock(file).should_receive(:puts).with(question_docs.to_json).once
    flexmock(File).should_receive(:open).with('_questions.json', 'w', Proc).and_yield(file)

    command_to_post_questions = "-X POST -H \"Content-Type: application/json\" https://will:pass@openphil.cloudant.com/bloom_filter/_bulk_docs -d @_questions.json"

    flexmock(questions_database).should_receive(:curl).with(command_to_post_questions).once

    flexmock(File).should_receive(:delete).with('_questions.json').once

    questions_database.post_questions(question_docs)
  end

  def test_can_update_the_number_of_questions_document
    questions_database = QuestionsDatabase.new({ username: 'will', password: 'pass', environment: 'bloom_filter' })

    flexmock(File).should_receive(:write).with('./views/lib/number_of_questions.js', 'module.exports = 90').once
    flexmock(questions_database).should_receive(:push_couchapp).once

    questions_database.update_number_of_questions_to(90)
  end

end
