

import loadCSVFile
import os
import question
import utilities
import random

#triviaFileName = "raw_data/ideas for trivia question data/tiny set of confidence interval questions/some_wits_and_wagers_questions.csv"
#use the script cleanConfidenceIntervalTriviaData.py to generate the clean csv file for this
triviaFileName = "raw_data/confidence interval trivia question data from Luke/OpenPhilanthropy_2_Final_clean_auto_generated.csv"

QUESTION_LIST_OF_DICTS = None

def loadQuestionData():
	global QUESTION_LIST_OF_DICTS
	global triviaFileName
	if QUESTION_LIST_OF_DICTS is None:
		QUESTION_LIST_OF_DICTS, headers = loadCSVFile.csvToListOfRowDictsAndHeaders(fileName=triviaFileName)

def formatNumberWithCommas(number):
	return "{:,}".format(number)

def testFormatNumberWithCommas():
	formatNumberWithCommas(0) == "0"
	formatNumberWithCommas(100) == "100"
	formatNumberWithCommas(1000) == "1,000"
	formatNumberWithCommas(100000) == "100,000"
	formatNumberWithCommas(1000000) == "1,000,000"
	formatNumberWithCommas(12351353233223) == "12,351,353,233,223"


def getQuestion(questionNumber):
	global QUESTION_LIST_OF_DICTS
	loadQuestionData()
	if questionNumber >= len(QUESTION_LIST_OF_DICTS):
		raise utilities.OutOfQuestionsException("There are only " + str(len(QUESTION_LIST_OF_DICTS)) + " questions available in category but you asked for question " + str(questionNumber))
	questionHash = QUESTION_LIST_OF_DICTS[questionNumber]
	correctAnswer = questionHash["Answer"]
	questionText = questionHash["Question"]
	answerType = "number"
	#put the percentile as the first item
	percentileOptions = [0.50, 0.70, 0.90]
	percentile = random.choice(percentileOptions)
	questionPieces = [percentile, "percentile", questionHash["Question"], correctAnswer]
	explanationText = "The correct answer is " + formatNumberWithCommas(correctAnswer) + "."
	difficulty = 1
	answerOptions = [questionHash['Option 1'], questionHash['Option 2'], questionHash['Option 3']]
	answerOptions.sort()
	rangeOfAnswers = int(answerOptions[-1]) - int(answerOptions[0])
	answerScale = "linear" if rangeOfAnswers < 1000 else "exponential"
	return question.Question(questionText=questionText, correctAnswer=correctAnswer, explanationText=explanationText, answerType=answerType, difficulty=1, questionPieces=questionPieces, questionNumber=questionNumber, category="confidence interval", subCategory=questionHash["Subcategory"], preambleText="", answerOptions=answerOptions, answerScale=answerScale, imageFile="", explanationImageFile="", imageUploadClient=None)



def numberedQuestion(questionStartNum, trialNum):
	curQuestionNum = trialNum + questionStartNum
	return getQuestion(questionNumber=curQuestionNum)

if __name__ == "__main__":
	questionStartNum = 1
	numQuestions = 2962

	for trialNum in xrange(numQuestions - 1):
		curQuestion = numberedQuestion(questionStartNum, trialNum)
		curQuestion.show()
