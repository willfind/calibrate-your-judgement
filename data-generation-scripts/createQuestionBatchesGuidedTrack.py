"""
This program generates the open philanthropy calibration app question GuidedTrack code for the program:
OpenPhil-load questions
https://www.guidedtrack.com/programs/3902
Simply replace all code in that program with the GuidedTrack that this program generates.
"""

import os
import loadCSVFile
import ast
import utilities
import constants
import datetime


def listToGuidedTrackCode(theList, quote):
	if isinstance(theList[0], list):
		#if the data was a list containing a list containing lists (e.g. the (x,y) pairs for points for correlation questions)
		#then we don't want to add quotes inside each list within a list within a list
		return str(theList)
	if quote:
		listAsString = '", "'.join([str(val) for val in theList])
		return '["' + listAsString + '"]'
	else:
		listAsString = ', '.join([str(val) for val in theList])
		return '[' + listAsString + ']' 

def guidedTrackCodeForCollection(theListName, theList, indents=0, quote=None):
	#print "the list is: ", theList
	startStr = "\t"*indents + ">> " + str(theListName) + ' = '
	if isinstance(theList[0], (str, unicode)):
		if quote == None: quote = True
		return startStr + listToGuidedTrackCode(theList, quote=quote)
	elif isinstance(theList[0], (int, float, long)):
		res = startStr + repr(theList)
		#if it mixes text and numbers there is the problem of single quotes around text 
		#so replace single quotes with double quotes
		res = res.replace("', '", '", "').replace("']", '"]').replace(", '", ', "')
		return res
	elif isinstance(theList[0], list):
		if quote == None: quote = True
		stringList = [listToGuidedTrackCode(val, quote=quote) for val in theList]
		return guidedTrackCodeForCollection(theListName=theListName, theList=stringList, indents=indents, quote=False)
	else: raise Exception("Unknown type of first element of theList: ", type(theList[0]))


def modifyURLToGetThumbnail(url):
	if url == "": return url
	#places an "m" just before the .jpg to make it into a thumbnail (technically "medium") size image
	for extension in [".jpg", ".png", ".gif", ".svg"]:
		if url.endswith(extension):
			return url.split(extension)[0] + "m" + extension 
	return url


def printGTLine(text, indents=0):
	print "\t"*indents + str(text) 


def printBatchInfo(indents):
	def out(name, value):
		print guidedTrackCodeForCollection(name, value, indents=indents)

	print "\t"*(indents-1) + "*if: batchNumber = " + str(curBatchNumber)
	#WAS print guidedTrackCodeForCollection("Q", questionTextList, indents=indents)
	out("questionTextList", questionTextList)
	#WAS print guidedTrackCodeForCollection("correctAnswers", correctAnswerList, indents=indents)
	out("correctAnswerList", correctAnswerList)
	out("explanationTextList", explanationTextList)
	out("answerTypeList", answerTypeList)
	out("questionPiecesList", questionPiecesList)
	#out("categoryList", categoryList)
	#out("subCategoryList", subCategoryList)
	out("minAnswersList", minAnswersList)
	out("maxAnswersList", maxAnswersList)
	out("preambleTextList", preambleTextList)
	out("answerOptionsList", answerOptionsList)
	#WAS out("questionURLs", imageURLList)
	out("imageURLList", imageURLList)
	#WAS out("questionThumbnailURLs", [modifyURLToGetThumbnail(url) for url in imageURLList])
	out("imageThumbnailURLList", [modifyURLToGetThumbnail(url) for url in imageURLList])
	out("explanationImageURLList", explanationImageURLList)


	#old
	#print  guidedTrackCodeForCollection("questionPiecesList", questionPieces, indents=indents)
	#print guidedTrackCodeForCollection("questionTrueValues", questionTrueValues, indents=indents)
	#print guidedTrackCodeForCollection("questionPart1s", questionPart1s, indents=indents)
	#print guidedTrackCodeForCollection("questionPart2s", questionPart2s, indents=indents)
	#print guidedTrackCodeForCollection("questionPart3s", questionPart3s, indents=indents)


def stringToPythonList(string):
	"""converts into a python list a string that came from converting a list into a string"""
	return ast.literal_eval(string)


def toGTList(string):
	"""turns a string in our special format into a guidedtrack list"""
	return utilities.CSVCompatibleListStringToList(string, doubleQuotesToSingleQuotes=True)

def confirmListsAllTheSameSize(listOfLists):
	size = None
	for curList in listOfLists:
		if size == None: size = len(curList)
		if len(curList) != size: raise Exception("Lists were not all the same size!")




if __name__ == "__main__":
	questionsPerBatch = 8
	questionFolder = constants.SAVE_DIRECTORY
	#the order of these MUST match the order they are introduced in the calibration app GuidedTrack code
	#questionFiles = ["city population.csv", "scatterplot correlation.csv", "simple math A.csv", "simple math B.csv", "politifact.csv", "irc trivia.csv"]
	questionFiles = ["city population.csv", "scatterplot correlation.csv", "simple math.csv", "politifact.csv", "irc trivia.csv", "confidence interval.csv"]

	maxQuestionsPerCategory = 24 #None

	questionPaths = [questionFolder + os.sep + questionFile for questionFile in questionFiles]
	thisScriptName = str(os.path.basename(__file__)) #"createQuestionBatches.py"

	print "\n\n\n\n\n"
	#tell them that they should not edit this GuidedTrack code
	print "-- OpenPhil-load questions --"
	print "-- DO NOT EDIT -- This file is automatically generated using " + thisScriptName + " on " + str(datetime.date.today()) + " -- DO NOT EDIT"
	for questionTypeNum, path in enumerate(questionPaths):
		questionTypeName = os.path.split(path)[1].rstrip(".csv") 

		#we now make the types all lowercase with no spaces
		simpifiedQuestionTypeName = questionTypeName.replace(" ", "_").lower()

		listOfRowDicts, headers = loadCSVFile.csvToListOfRowDictsAndHeaders(path)
		curQuestionsInBatch = 0
		curTotalQuestionsForCategory = 0
		curBatchNumber = 0
		totalIndents = 2


		print "\n\n\n\n\n"
		print "--------- QUESTIONS FOR: " + str(simpifiedQuestionTypeName) + " -----------"
		print ""

		print "\t"*(totalIndents-2) + '*if: ActiveQuestionSet = "' + str(simpifiedQuestionTypeName) + '"'
		#this sets the category number for the category of these questions
		printGTLine(">> SetNB = " + str(questionTypeNum+1), indents=totalIndents-1) 
		
		for rowDict in listOfRowDicts:

			if curQuestionsInBatch % questionsPerBatch == 0:
				if curBatchNumber > 0:
					printBatchInfo(totalIndents)

				questionTextList = []
				correctAnswerList = []
				explanationTextList = []
				answerTypeList = [] #each entry should be one of ["true-false", "choice", "checkbox", "number", "text"]
				questionPiecesList = []
				preambleTextList = []
				answerOptionsList = []
				imageURLList = []
				explanationImageURLList = []
				minAnswersList = []
				maxAnswersList = []

				#questionTrueValues = []
				#questionPart1s = []
				#questionPart2s = []
				#questionPart3s = []
				#questionURLs = []

				curBatchNumber += 1
				curQuestionsInBatch = 0
				

			questionTextList.append(rowDict["questionText"].replace('"', "'"))
			correctAnswerList.append(rowDict["correctAnswer"])
			explanationTextList.append(rowDict["explanationText"])
			answerTypeList.append(rowDict["answerType"])
			questionPiecesList.append(toGTList(rowDict["questionPieces"]))
			minAnswersList.append(rowDict["minAnswers"])
			maxAnswersList.append(rowDict["maxAnswers"])
			preambleTextList.append(rowDict["preambleText"])
			answerOptionsList.append(toGTList(rowDict["answerOptions"]))
			imageURLList.append(rowDict["imageURL"])
			explanationImageURLList.append(rowDict["explanationImageURL"])

			
			curQuestionsInBatch += 1
			curTotalQuestionsForCategory += 1
			if not (maxQuestionsPerCategory is None):
				if curTotalQuestionsForCategory >= maxQuestionsPerCategory: 
					#print "breaking from question type"
					break

		confirmListsAllTheSameSize([questionTextList, correctAnswerList, explanationTextList, answerTypeList, questionPiecesList, minAnswersList, maxAnswersList, preambleTextList, answerOptionsList, imageURLList, explanationImageURLList])
		printBatchInfo(totalIndents)

	"""
	*if: not highestBatchNumberForEachType
		>> highestBatchNumberForEachType = {} 

	*if: not highestBatchNumberForEachType[ActiveQuestionSet]
		--store this so there is always a batch number for the current type
		>> highestBatchNumberForEachType[ActiveQuestionSet] = -1
	
	*if: batchNumber < highestBatchNumberForEachType[ActiveQuestionSet]
		Woops, the batchNumber should always increase! 
		We rely on the assumption of increasing batchNumber to decide if we should re-randomize question order
		*quit

	--it's important to only shuffle these once, we can't have the order keep changing!
	*if:  batchNumber > highestBatchNumberForEachType[ActiveQuestionSet]
		--randomize the order of the question within the current small BATCH
		>>QuestionOrder=[]
		>>count=1
		*repeat: questionTextList.size
			>>QuestionOrder.add(count)
			>>count=count+1
		>>QuestionOrder.shuffle

		>> highestBatchNumberForEachType[ActiveQuestionSet] = batchNumber 
	"""

	print "\n"
	printGTLine("*if: not highestBatchNumberForEachType")
	printGTLine(">> highestBatchNumberForEachType = {}", indents=1)

	printGTLine("*if: not highestBatchNumberForEachType[ActiveQuestionSet]")
	printGTLine("--store this so there is always a batch number for the current type", indents=1)
	printGTLine(">> highestBatchNumberForEachType[ActiveQuestionSet] = -1", indents=1)

	printGTLine("*if: batchNumber < highestBatchNumberForEachType[ActiveQuestionSet]")
	printGTLine("Woops, the batchNumber should always increase!", indents=1)
	printGTLine("We rely on the assumption of increasing batchNumber to decide if we should re-randomize question order", indents=1)
	printGTLine("*quit", indents=1)

	printGTLine("--it's important to only shuffle these once, we can't have the order keep changing!")
	printGTLine("*if: batchNumber > highestBatchNumberForEachType[ActiveQuestionSet]")
	printGTLine("--randomize the order of the question within the current small BATCH",indents=1)
	printGTLine(">>QuestionOrder=[]", indents=1)
	printGTLine(">>count=1", indents=1)
	printGTLine("*repeat: questionTextList.size", indents=1)
	printGTLine(">>QuestionOrder.add(count)", indents=2)
	printGTLine(">>count=count+1", indents=2)
	printGTLine(">>QuestionOrder.shuffle", indents=1)
	printGTLine(">> highestBatchNumberForEachType[ActiveQuestionSet] = batchNumber", indents=1)
	print "\n\n"
	print "-- DO NOT EDIT -- This file is automatically generated using " + thisScriptName + " -- DO NOT EDIT"
	print "\n\n\n\n\n\n"
	
	print "-"*30
	print "The GuidedTrack code is above! Paste it into the appropriate GuidedTrack program, probably 'OpenPhil-load questions'"


