require './scripts/questions_database'
require 'io/console'

SCHEME = 'https://'
HOST = 'openphil.cloudant.com'

def get_environment
  print "Enter the name of the database you want to add questions to: "
  gets.chomp
end

def get_username
  print "Enter your username for the database: "
  gets.chomp
end

def get_password
  print "Enter your password for the database: "
  password = STDIN.noecho(&:gets).chomp
  print "\n"
  password
end

def get_filename
  print "Enter the name of the file the questions are saved in: "
  gets.chomp
end

summary = AddQuestionsToDatabase.given({ environment: get_environment, username: get_username, password: get_password, filename: get_filename })

puts "questions added: #{summary[:questions_added]}"
puts "questions replaced: #{summary[:questions_replaced]}"
