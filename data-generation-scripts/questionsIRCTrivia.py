
import urllib
#from urllib import request
from bs4 import BeautifulSoup
import unicodedata
import loadCSVFile
import os
import question
import utilities

QUESTION_LIST_OF_DICTS = None

def loadQuestionData():
	global QUESTION_LIST_OF_DICTS
	if QUESTION_LIST_OF_DICTS is None:
		QUESTION_LIST_OF_DICTS, headers = loadCSVFile.csvToListOfRowDictsAndHeaders(fileName="raw_data" + os.sep + "irc-wiki-trivia-clean-3.csv")


def wordCount(text):
	cleanText = text.strip().rstrip("!").rstrip(".").rstrip("?").rstrip(",")
	return len(cleanText.split(" "))


def getQuestion(questionNumber):
	global QUESTION_LIST_OF_DICTS
	loadQuestionData()
	if questionNumber >= len(QUESTION_LIST_OF_DICTS):
		raise utilities.OutOfQuestionsException("There are only " + str(len(QUESTION_LIST_OF_DICTS)) + " questions available in category IRCWiki but you asked for question " + str(questionNumber))
	questionHash = QUESTION_LIST_OF_DICTS[questionNumber]
	correctAnswer = questionHash["Answer"]

	#make it into an integer if it's a written out integer like "twelve"
	correctAnswer = utilities.replaceTextIntegerWithInteger(correctAnswer)
	#print "correctAnswer", correctAnswer
	if isinstance(correctAnswer, (int, long)):
		answerType = "number"
		questionText = questionHash["Question"] + "  (a number)" 
	else:
		correctAnswer = correctAnswer.lower()
		if correctAnswer.startswith("the "): correctAnswer = correctAnswer[4:]
		if correctAnswer.startswith("an "): correctAnswer = correctAnswer[3:]
		if correctAnswer.startswith("a "): correctAnswer = correctAnswer[2:]
		correctAnswer = correctAnswer.strip()
		if len(correctAnswer) == 0: raise Exception("Empty correctAnswer!")
		answerType = "text"
		words = wordCount(correctAnswer)
		questionText = questionHash["Question"]
		if words == 1:
			questionText += "  (" + str(words) + " word)" 
		else:
			questionText += "   (format: " + utilities.fillNonBlanksWithX(correctAnswer) + ")"
			#questionText += "  (" + str(words) + " words)" 
	questionPieces = [questionHash["Subcategory"], questionHash["Question"], answerType, correctAnswer]
	explanationText = "The correct answer is '" + str(correctAnswer) + "'."
	difficulty = 1
	return question.Question(questionText=questionText, correctAnswer=correctAnswer, explanationText=explanationText, answerType=answerType, difficulty=difficulty, questionPieces=questionPieces, questionNumber=questionNumber, category="irc trivia", subCategory=questionHash["Subcategory"], preambleText="", answerOptions="", answerScale="", imageFile="", explanationImageFile="", imageUploadClient=None)



if __name__ == "__main__":
	questionStartNum = 1
	numQuestions = 1682

	for trialNum in xrange(numQuestions - 1):
		curQuestionNum = trialNum + questionStartNum
		curQuestion = getQuestion(questionNumber=curQuestionNum)
		curQuestion.show()
