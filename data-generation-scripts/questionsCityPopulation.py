import random
import utilities
import loadCSVFile
import question
import os

QUESTION_LIST_OF_DICTS = None

def loadQuestionData():
	global QUESTION_LIST_OF_DICTS
	if QUESTION_LIST_OF_DICTS is None:
		QUESTION_LIST_OF_DICTS, headers = loadCSVFile.csvToListOfRowDictsAndHeaders(fileName="raw_data" + os.sep + "city_populations.csv")


def getQuestion(questionNumber):
	global QUESTION_LIST_OF_DICTS
	#utilities.setRandomSeed(questionNumber) #now done a level above
	loadQuestionData()

	randomPos1 = random.randint(0, len(QUESTION_LIST_OF_DICTS)-1)
	randomItem1 = QUESTION_LIST_OF_DICTS[randomPos1]
	city1, country1, population1 = randomItem1["City"], randomItem1["Country"], randomItem1["Population"]

	randomPos2 = randomPos1
	while True:
		randomPos2 = random.randint(0, len(QUESTION_LIST_OF_DICTS)-1)
		randomItem2 = QUESTION_LIST_OF_DICTS[randomPos2]
		city2, country2, population2 = randomItem2["City"], randomItem2["Country"], randomItem2["Population"]

		#if we aren't comparing a city to itself
		if randomPos2 != randomPos1:
			#if the two cities don't have populations within 0.1 million of each other
			if (round(population1/1000000.0,1) != round(population2/1000000.0, 1)):
				#print "population1 mil", round(population1/1000000.0,1)
				#print "population2 mil", round(population2/1000000.0,1)
				break

	#Document example: According to WorldAtlas.com as of March 2016, which city had a larger metro population in 2015, Sydney (Australia) or Portland (USA, Oregon)?

	location1 = city1 + ", " + country1 
	location2 = city2 + ", " + country2
	
	#questionText = location1 + "" +" had a larger metro population than " + location2 + "" + " in 2016 according to WorldAtlas.com."
	questionText = location1 + "" +" had a larger metro population than " + location2 + "" + " in 2016."
	inequality = ">"
	if inequality == ">":
		correctAnswer = str((population1 > population2))
	elif inequality == "<":
		correctAnswer = str((population1 < population2))
	else: raise Exception("Unknown comparison!")
	#trueValue = str(population1) + "|" + str(population2)

	difficulty = min(population1, population2)/float(max(population1, population2)) #a score between 0 and 1

	questionPieces = [city1, country1, population1, inequality, city2, country2, population2]
	explanationText = str(city1) + " has " + utilities.fancyFormatNumber(population1) + "people whereas " + str(city2) + " has " + utilities.fancyFormatNumber(population2) + "people."
	return question.Question(questionText=questionText, correctAnswer=correctAnswer, explanationText=explanationText, answerType="true-false", difficulty=difficulty, questionPieces=questionPieces, questionNumber=questionNumber, category="city population", subCategory="", preambleText="", answerOptions=[True, False], answerScale="", imageFile="", explanationImageFile="", imageUploadClient=None)
	#return question.Question(questionText=questionText, answer=answer, trueValue=trueValue, difficulty=difficulty, category="city population", part1=city1, part2=">", part3=city2)





if __name__ == "__main__":
	questionStartNum = 1
	numQuestions = 5000

	for trialNum in xrange(numQuestions):
		curQuestionNum = trialNum + questionStartNum
		curQuestion = getQuestion(questionNumber=curQuestionNum)
		curQuestion.show()
