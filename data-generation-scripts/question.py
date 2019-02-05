import loadCSVFile
import utilities
import os
import imgur
import datetime
import sys
#import question
import constants
import json

SAVE_DIRECTORY = constants.SAVE_DIRECTORY

CATEGORY_QUESTION_NUMBER_TO_UNIQUE_ID = {} #maps a category into a hash table that maps question number into UniqueID for that question number
UNIQUE_IDS_SAVED = set({}) #a set of all the unique IDs we've saved (for all categories lumped together) so that we never re-add a question with the same unique id. 
EXCEL_MAX_INT = 10**15-1

def generateUniqueID(data):
	global EXCEL_MAX_INT
	theID = abs(int(utilities.hashCode(data) % min(sys.maxint, EXCEL_MAX_INT)))
	return theID

class Question:
	#def __init__(self, questionText, correctAnswer, trueValue, difficulty, category, part1, part2=None, part3=None, localImageFile=None, imageUploadClient=None):
	def __init__(self, questionText, correctAnswer, explanationText, answerType, difficulty, questionPieces, questionNumber, category, subCategory="", minAnswers=1, maxAnswers=1, preambleText="", answerOptions="", answerScale="", imageFile="", explanationImageFile="", imageUploadClient=None):
		self.questionText = questionText 
		self.correctAnswer = correctAnswer
		self.explanationText = explanationText
		self.answerType = answerType
		self.difficulty = difficulty
		self.questionPieces = questionPieces
		self.questionNumber = questionNumber
		self.category = category
		self.subCategory = subCategory
		self.minAnswers = minAnswers
		self.maxAnswers = maxAnswers
		self.preambleText = preambleText
		self.answerOptions = answerOptions
		self.answerScale = answerScale
		self.imageFile = imageFile
		self.imageURL = "" #this will get taken from imageFile (if imageFile is a URL) or set automatically if imageFile is uploaded
		self.explanationImageFile = explanationImageFile
		self.explanationImageURL = ""
		self.timeWhenAdded = datetime.datetime.utcnow().strftime('%l:%M%p UTC, %b %d, %Y') # Example: 7:01PM EDT, Aug 28, 2016

		possibleAnswerTypes = ["true-false", "choice", "checkbox", "number", "text"]
		if not answerType in possibleAnswerTypes:
			raise Exception("Invalid answerType '" + str(answerType) + "' was not in " + str(possibleAnswerTypes))

		#a (very very likely to be) unique code for this question
		self.uniqueID = generateUniqueID([self.imageFile, self.preambleText, self.questionText])

		#if they've direclty given us a URL instead of a local file, just use that URL
		if imageFile.startswith("http"):
			self.imageURL = imageFile
		if explanationImageFile.startswith("http"):
			self.explanationImageURL = explanationImageFile

		#on the other hand, if they give us local files, we'll upload them and get URLs for them
		if not (imageUploadClient is None):
			if imageFile != "" and self.imageURL == "":
				self.imageURL = utilities.uploadImageFile(imageFile, imageUploadClient)
			if explanationImageFile != "" and self.explanationImageURL == "":
				if explanationImageFile == imageFile: 
					self.explanationImageURL = self.imageURL
				else:
					self.explanationImageURL = utilities.uploadImageFile(explanationImageFile, imageUploadClient)


	def alreadySavedToCSV(self):
		"""checks whether this question has not already been saved to its category csv file!"""
		global UNIQUE_IDS_SAVED
		if self.uniqueID in UNIQUE_IDS_SAVED: return True #we already have this unique ID so don't save the question again (even if it has a different question number than)
		questionNumToUniqueIDHash = getQuestionNumberToUniqueIDHash(self.category)
		#print "questionNumToUniqueIDHash", questionNumToUniqueIDHash
		if self.questionNumber in questionNumToUniqueIDHash:
			#print "found question number!"
			savedUniqueID = questionNumToUniqueIDHash[self.questionNumber] 
			if savedUniqueID != self.uniqueID: 
				raise utilities.QuestionMismatchException("The question with question number " + str(self.questionNumber) + " had a previously saved unique id " + str(savedUniqueID) + " but now it has unique id " + str(self.uniqueID) + ". Most likely this means the question generation algorithm changed, and the whole file of questions of this category '" + self.category + "' needs to be regenerated. The question text was: '" + str(self.questionText) + "'")
			return True
		else:
			#print "didn't find question number!"
			return False

	def show(self):
		print self.json()

	def json(self):
		return json.dumps({
		    '_id': str(self.questionNumber),
		    'questionID': self.uniqueID,
		    'text': self.questionText,
		    'correctAnswer': self.correctAnswer,
		    'explanation': self.explanationText,
		    'type': self.answerType,
		    'difficulty': self.difficulty,
		    'pieces': self.questionPieces,
		    'category': self.category,
		    'subCategory': self.subCategory,
		    'minAnswers': self.minAnswers,
		    'maxAnswers': self.maxAnswers,
		    'preamble': self.preambleText,
		    'answerOptions': self.answerOptions,
		    'answerScale': self.answerScale,
		    'imageFile': self.imageFile,
		    'explanationImageFile': self.explanationImageFile,
		    'image': self.imageURL,
		    'explanationImage': self.explanationImageURL,
		    'timeWhenAdded': self.timeWhenAdded
		})

	def save(self):
		"""append to its corresponding csv file for its category of question 
		(but only if this question number isn't there already, and there isn't yet any question with this unique ID)"""
		if self.alreadySavedToCSV(): #this makes sure we don't readd a question to a file if it's already there!
			print "For category '" + str(self.category) + "' question " + str(self.questionNumber) + " was already saved so not adding to csv. Text was: " + str(self.questionText)
		else:
			fullFilePath = categoryCSVPath(self.category)
			utilities.forceMakeDirectory(SAVE_DIRECTORY)

			listToStr = utilities.listToCSVCompatibleListString

			#print "self.answerOptions", self.answerOptions

			#print "writing csv: ", self.uniqueID
			output = [self.questionNumber, self.uniqueID, self.questionText, self.correctAnswer, self.explanationText, self.answerType, self.difficulty, listToStr(self.questionPieces), self.category, self.subCategory, self.minAnswers, self.maxAnswers, self.preambleText, listToStr(self.answerOptions), self.imageFile, self.explanationImageFile, self.imageURL, self.explanationImageURL, self.timeWhenAdded]
			
			if not os.path.exists(fullFilePath): #if the file doesn't exist, we'll create it
				#header = ["question_text", "correctAnswer", "true_value", "difficulty", "part1", "part2", "part3", "local file", "url", "category", "unique id", "time added"]
				#these were used before Oct 24, 2017:
				#header = ["questionNumber", "uniqueID", "questionText", "correctAnswer", "explanationText", "answerType", "difficulty", "questionPieces", "category", "subCategory", "minAnswers", "maxAnswers", "preambleText", "answerOptions", "imageFile", "explanationImageFile", "imageURL", "explanationImageURL", "timeWhenAdded"]
				#switched to these to match what the cloudant database uses:
				header = ["_id", "questionID", "text", "correctAnswer", "explanation", "type", "difficulty", "pieces", "category", "subCategory", "minAnswers", "maxAnswers", "preamble", "answerOptions", "imageFile", "explanationImageFile", "image", "explanationImage", "timeWhenAdded"]
				mode = "write"
			else: #if the file exists, we'll just append to it
				header = []
				mode = "append"
			print "For category '" + str(self.category) + "' saving question " + str(self.questionNumber) + " to " + str(fullFilePath)
			loadCSVFile.writeCSV(fullFilePath, [output], header=header, topComments=[], lineSeperator="\n", mode=mode)
			#update our in memory knowledge that we already have this question so that we don't accidentally save it again later!
			questionNumToUniqueIDHash = getQuestionNumberToUniqueIDHash(self.category)
			questionNumToUniqueIDHash[self.questionNumber] = self.uniqueID
			UNIQUE_IDS_SAVED.add(self.uniqueID)


def makeQuotedString(value):
	return '"'+str(value)+'"'

def categoryCSVPath(category):
	return SAVE_DIRECTORY + os.sep + str(category) + ".csv"

def getQuestionNumberToUniqueIDHash(category):
	global CATEGORY_QUESTION_NUMBER_TO_UNIQUE_ID
	global UNIQUE_IDS_SAVED #will be all unique ids ever saved for all categories being used
	if category in CATEGORY_QUESTION_NUMBER_TO_UNIQUE_ID:
		return CATEGORY_QUESTION_NUMBER_TO_UNIQUE_ID[category]
	else:
		csvFileName = categoryCSVPath(category)
		#print "looking for csvFileName", csvFileName
		if os.path.exists(csvFileName):
			result = utilities.getQuestionNumberToUniqueIDHash(csvFileName)
			for curQuestionNumber, uniqueID in result.iteritems():
				UNIQUE_IDS_SAVED.add(uniqueID)
		else:
			result = {}
		CATEGORY_QUESTION_NUMBER_TO_UNIQUE_ID[category] = result
		return result

def uploadImageFile(imageFile, imageUploadClient):
	album = "tHLYL" #this is the album "correlation scatterplots test" on imgur.com
	if imageFile == "": raise Exception("Since you passed an imageUploadClient you should include an imageFile to upload")
	fileName = os.path.split(imageFile)[1]
	imageInfoHash = imgur.uploadImage(fromPath=imageFile, client=imageUploadClient, name=fileName, album=album)
	return imageInfoHash["link"]


