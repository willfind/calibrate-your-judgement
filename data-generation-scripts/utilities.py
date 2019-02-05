
import random
import numpy
import os
import sys
import loadCSVFile
import imgur

class OutOfQuestionsException(Exception):
	pass

class QuestionMismatchException(Exception):
	pass



def categoryCSVPath(category):
	return SAVE_DIRECTORY + os.sep + str(category) + ".csv"	

def uploadImageFile(imageFile, imageUploadClient):
	album = "tHLYL" #this is the album "correlation scatterplots test" on imgur.com
	if imageFile == "": raise Exception("Since you passed an imageUploadClient you should include an imageFile to upload")
	fileName = os.path.split(imageFile)[1]
	imageInfoHash = imgur.uploadImage(fromPath=imageFile, client=imageUploadClient, name=fileName, album=album)
	return imageInfoHash["link"]


def configureImageUpload(numQuestions=None):
	print "\n\nWe will be uploading images automatically to imgur...\n"

	if not (numQuestions is None) and numQuestions > 10: 
		confirmAction("Are you sure you want to add up to " + str(numQuestions) + " images to imgur? ")

	imageUploadClient = imgur.authenticate()
	print "\n\n"
	return imageUploadClient


#only goes up to thirty right now
numbersAsText = ['zero', 'one','two','three','four','five','six','seven','eight','nine','ten','eleven','twelve','thirteen','fourteen','fifteen','sixteen','seventeen','eighteen','nineteen','twenty','twentyone','twentytwo','twentythree','twentyfour','twentyfive','twentysix','twentyseven','twentyeight','twentynine','thirty']

def fillNonBlanksWithX(text):
	result = []
	for char in text:
		if char != " ":
			result.append("x")
		else:
			result.append(" ")
	return "".join(result)

def testFillNonBlanksWithX():
	assert fillNonBlanksWithX("hi there mr happy guy!") == "xx xxxxx xx xxxxx xxxx"

def replaceTextIntegerWithInteger(text):
	if not isinstance(text, (str, unicode)): return text
	cleanText = text.lower().strip().replace(" ", "").replace("-", "")
	try:
		index = numbersAsText.index(cleanText)
		return index
	except ValueError:
		return text

def testTextIntegerToInteger():
	assert replaceTextIntegerWithInteger("Zero") == 0
	assert replaceTextIntegerWithInteger("SEVEN") == 7
	assert replaceTextIntegerWithInteger("twenty    - SEVEN") == 27
	assert replaceTextIntegerWithInteger("moose head 42") == "moose head 42"

def quoteString(val):
	if isinstance(val, (str, unicode)):
		val = val.replace('"', "&*quote*&")
		result = '"' + val + '"'
		result = result.replace("|", "\\|")
		return result
	else: return str(val)

def dequoteString(val):
	#print "dequoting: ", str(val)
	if isinstance(val, (str, unicode)) and len(val) == 0: return val
	if val.startswith('"') and val.endswith('"'):
		result = val[1:-1]
		result = result.replace("\\|", "|")
		result = result.replace("&*quote*&", '"')
		return result
	elif val.startswith('"'):
		raise Exception("Left side quote only!")
	elif val.endswith('"'):
		raise Exception("Right side quote only!")
	elif val == "True": return True
	elif val == "False": return False
	else:
		try:
			return int(val)
		except ValueError:
			pass
		try:
			return float(val)
		except ValueError:
			pass
		if val.startswith("[") and val.endswith("]"):
			split = val.lstrip("[").rstrip("]").split(",")
			split = [dequoteString(value.strip()) for value in split]
			#print "split: ", split
		 	return split
		raise Exception("Unknown value of type: " + str(type(val)) + " with value '" + str(val) + "'")


def testQuoteString():
	string = 'hi there my friend|and "some" stuff I like|whatever you say'
	assert string == dequoteString(quoteString(string))

def listToCSVCompatibleListString(values):
	"""encode a list as a CSV file compatible string (i.e. one not containing commas)"""
	return "[" + "|".join([quoteString(val) for val in values]) + "]"

def replaceDoubleQuoteIfString(value):
	if isinstance(value, (str, unicode)):
		return value.replace('"', "'")
	else:
		return value

def stripOnceLeft(string, toStrip):
	if string.startswith(toStrip):
		return string[len(toStrip):]
	return string

def test_stripOnceLeft():
	assert stripOnceLeft("hiyamyfriend", "hiy") == "amyfriend"

def stripOnceRight(string, toStrip):
	if string.endswith(toStrip):
		return string[:-len(toStrip)]
	return string

def test_stripOnceRight():
	assert stripOnceRight("hiyamyfriend", "iend") == "hiyamyfr"



def CSVCompatibleListStringToList(string, doubleQuotesToSingleQuotes=False):
	#print "converting to list:" + str(string)
	#string = string.replace('"[', '[')
	#string = string.replace(']"', '[')
	#print 'string.lstrip("[")', string.lstrip("[")
	#pieces = string.lstrip("[").rstrip("]").split("|")
	string = stripOnceRight(stripOnceLeft(string, "["), "]")
	pieces = string.split("|")
	if doubleQuotesToSingleQuotes:
		output = [replaceDoubleQuoteIfString(dequoteString(piece)) for piece in pieces]
	else:
		output = [dequoteString(piece) for piece in pieces]
	return output


def testCSVCompatibleListString1():
	values = [1,2,3,"four","f", 6,9.2, True, False]
	string = listToCSVCompatibleListString(values)  
	print "string", string
	assert string == '[1|2|3|"four"|"f"|6|9.2|True|False]'
	after = CSVCompatibleListStringToList(string)
	print "after", after
	assert values == after


def testCSVCompatibleListString2():
	values = [[1,2],[3,4]]
	string = listToCSVCompatibleListString(values)  
	print "string", string
	after = CSVCompatibleListStringToList(string)
	print "after", after
	assert values == after


def setRandomSeed(seed):
	random.seed(seed)
	numpy.random.seed(seed)

def hashCode(toHash):
	return hash(str(toHash))

def pickComparisonDirection(trueValue, comparisonValue):
	if random.uniform(0,1) < 0.5: #randomly choose whether it's < or > that we compare
		comparisonWord = "smaller"
		inequality = "<"
		if trueValue < comparisonValue: answer = "True"
		else: answer = "False"
	else:
		comparisonWord = "bigger"
		inequality = ">"
		if trueValue > comparisonValue: answer = "True"
		else: answer = "False"
	return comparisonWord, inequality, answer


def forceMakeDirectory(path):
	"""create this directory if it doesn't yet exist"""
	if not os.path.exists(path):
		os.makedirs(path)


def confirmAction(text):
	result = get_input(text + "\n\n")
	if not (result in ["y", "Y", "yes", "Yes", "YES"]):
		print "Quitting..."
		sys.exit(0)

def get_input(string):
	''' Get input from console regardless of python 2 or 3 '''
	try:
		return raw_input(string)
	except:
		return input(string)

def removeFromStartOfText(phraseToRemove, text):
	if text.lower().startswith(phraseToRemove.lower()):
		return text[len(phraseToRemove):]
	else:
		return text

def testRemoveFromStartOfText():
	assert removeFromStartOfText("dog", "DoGfishBoom") == "fishBoom"
	assert removeFromStartOfText("dog", "doffishBoom") == "doffishBoom"



def closestInteger(value):
	return int(round(value))

def numberToReasonableRoundedString(value):
	#if it's close to zero already display more decimals 
	if abs(value) < .1:
		return str(round(value, 3))
	elif abs(value) < 1:
		return str(round(value, 2))
	#if it's basically already an integer, round it to one
	if abs(int(round(value)) - value) < 1E-6:
		return str(closestInteger(value))
	#if it's large, don't show decimals
	elif abs(value) > 1000:
		return str(closestInteger(value))
	else:
		return str(round(value, 1))


def formatNumber(number):
	if type(number) not in [type(0), type(0L)]:
		raise TypeError("Sorry, the input must be an integer.")
	if number < 0:
		return '-' + formatNumber(-number)
	result = ''
	while number >= 1000:
		number, r = divmod(number, 1000)
		result = ",%03d%s" % (r, result)
	return "%d%s" % (number, result)

def fancyFormatNumber(number):
	if number > 2000 and number < 1000000:
		return str(round(number/1000.0,1)) + " thousand "
	elif number >= 1000000:
		return str(round(number/1000000.0,1)) + " million "
	else:
		return str(number)

def getQuestionNumberToUniqueIDHash(csvFileName):
	listOfRowDicts, headers = loadCSVFile.csvToListOfRowDictsAndHeaders(csvFileName, toPythonObjects=True)
	#print "listOfRowDicts", listOfRowDicts
	#print "\n\n\n"
	questionNumberToUniqueID = {}
	for curDict in listOfRowDicts:
		#print "curDict", curDict
		questionNumber = curDict["questionNumber"]
		uniqueID = curDict["uniqueID"]
		questionNumberToUniqueID[questionNumber] = uniqueID
	return questionNumberToUniqueID


#def saveQuestion(fileName):
#	writeCSV(filename, listOfLists, header=[], topComments = [], lineSeperator="\n", mode="write")
