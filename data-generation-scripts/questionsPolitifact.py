import json
from bs4 import BeautifulSoup
import unicodedata
import question
from datetime import datetime
import utilities
import copy

QUESTION_NUMBER_TO_QUESTION = {}
FIRST_TIME_DOWNLOADING = True
SECS_DELAY_BETWEEN_PAGE_DOWNLOADS = 1
FACTS_PER_PAGE = None
MERGE_PANTS_ON_FIRE_INTO_FALSE_CATEGORY = False

FLIP_ANSWER_OPTIONS = ["No Flip", "Half Flip", "Full Flop"]
TRUTH_ANSWER_OPTIONS = ["True", "Mostly True", "Half-True", "Mostly False", "False", "Pants on Fire!"]

with open('./raw_data/politifact/truth-o-meter.json') as dataFile:
	rawQuestionData = json.load(dataFile)

def questionFromData(questionData, questionNumber):
	global FLIP_ANSWER_OPTIONS
	global TRUTH_ANSWER_OPTIONS
	fact = factFrom(questionData)
	source = str(fact["source"]).replace("  ", " ").strip()
	preambleText = "What rating did PolitiFact give the following statement made by " + source + " on " + str(fact["when"]) + "?"
	questionText = str(fact["claim"]).strip()
	questionText = utilities.removeFromStartOfText("Says that", questionText)
	questionText = utilities.removeFromStartOfText("Says", questionText)
	questionText = utilities.removeFromStartOfText("Say", questionText)
	questionText = utilities.removeFromStartOfText("That", questionText)
	questionText = source + " claim: " + questionText

	questionPieces = [source, fact["claim"], fact["when"], fact["mugshot"], fact["veracity"]]
	explanationText = "The statement was rated '" + str(fact["veracity"]) + "' by PolitiFact"
	answerType="checkbox"
	correctAnswer = fact["veracity"].strip()
	if correctAnswer in FLIP_ANSWER_OPTIONS:
		flopQuestion = True
		answerOptions = copy.copy(FLIP_ANSWER_OPTIONS)
		minAnswers = 1
		maxAnswers = 1
	elif correctAnswer in TRUTH_ANSWER_OPTIONS:
		flopQuestion = False
		answerOptions = copy.copy(TRUTH_ANSWER_OPTIONS)
		minAnswers = 2
		maxAnswers = 2
	else: raise Exception("Invalid answer option '" + str(correctAnswer) + "'")
	difficulty = 1
	category="politifact"
	subcategory = source
	imageFile = "" #we turned off mugshots due to copyright issues + size issues at Luke's request

	if MERGE_PANTS_ON_FIRE_INTO_FALSE_CATEGORY and (correctAnswer in TRUTH_ANSWER_OPTIONS):
		if "pants" in correctAnswer.lower(): #turn "Pants on Fire!" into "False"
			correctAnswer = "False"
			assert correctAnswer in TRUTH_ANSWER_OPTIONS

		answerOptions.remove("Pants on Fire!")
		assert len(answerOptions) < TRUTH_ANSWER_OPTIONS

	if flopQuestion: return None
	return question.Question(questionText=questionText, correctAnswer=correctAnswer, explanationText=explanationText, answerType=answerType, difficulty=difficulty, questionPieces=questionPieces, questionNumber=questionNumber, category=category, subCategory=subcategory, minAnswers=minAnswers, maxAnswers=maxAnswers, preambleText=preambleText, answerOptions=answerOptions, answerScale="", imageFile=imageFile, explanationImageFile="", imageUploadClient=None)

def factFrom(questionData):
	output = {}
	output["veracity"] = questionData["ruling"]["ruling"]
	quote = cleanText(BeautifulSoup(questionData['statement'], 'html.parser').text)
	output["quote"] = quote
	output["mugshot"] = questionData['speaker']['canonical_photo']
	output["source"] = cleanText(questionData['speaker']['first_name'] + ' ' + questionData['speaker']['last_name'])
	output["claim"] = quote
	output["when"] = humanReadableStatementDateFrom(questionData)
	return output

def humanReadableStatementDateFrom(questionData):
	return datetime.strptime(questionData['statement_date'], '%Y-%M-%d').strftime('%A, %B %d, %Y')

def cleanText(text):
	text = text.replace(u"\u2019", "'").replace(u'\xa0', u' ').replace("\n",'').replace("\r",'').replace("\t",'')
	return unicodedata.normalize('NFKD', text).encode('ascii','ignore').strip()

if __name__ == "__main__":
	for i, questionData in enumerate(rawQuestionData):
		curQuestion = questionFromData(questionData, i + 1)
		if curQuestion == None: continue
		curQuestion.show()
