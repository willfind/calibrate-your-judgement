# -*- encoding: utf-8 -*-
import loadCSVFile
import os
import re


def isRankOrder(text):
	if loadCSVFile.isNumber(text): return False
	text = text.lower().strip()
	if text.endswith("st") or text.endswith("nd") or text.endswith("rd") or text.endswith("th"):
		try:
			intVersion = int(text[:-2])
			return True
		except ValueError:
			return False


def test_isRankOrder():
	assert isRankOrder("1st")
	assert isRankOrder("2nd")
	assert isRankOrder("3rd")
	assert isRankOrder("4th")
	assert isRankOrder("5th")
	assert isRankOrder("472nd")
	assert isRankOrder("45th")
	assert not isRankOrder('dog')
	assert not isRankOrder('52')


def isDecadeNumber(text):
	if not isinstance(text, (str, unicode)): return False
	text = text.lower()
	if text[-1] == 's':
		text = text[:-1].strip("'")
		if len(text) == 4:
			try:
				num = int(text)
				return True
			except ValueError:
				pass
	return False


def test_isDecadeNumber():
	assert isDecadeNumber('1990s')
	assert isDecadeNumber('2000s')
	assert isDecadeNumber('1950s')
	assert not isDecadeNumber('1950')
	assert not isDecadeNumber('195')
	assert not isDecadeNumber('frogs')


def convertTextToNumberIfPossibleAllowingUnits(toConvert):
	if loadCSVFile.isNumber(toConvert): return toConvert
	toConvert = toConvert.lower()
	toConvert = re.sub(r',\s*(\d\d\d)', r'\1', toConvert.strip())
	units = [["%", 1], ["hundred", 100], ["thousand", 1000], ["million", 1000000], ["billion", 1000000000], ["bilion", 1000000000], ["trillion", 1000000000000]]
	for unit in units:
		if toConvert.endswith(unit[0]):
			numberPartText = toConvert[:-len(unit[0])].strip()
			numberPart = loadCSVFile.tryToConvertToNumber(numberPartText)
			if loadCSVFile.isNumber(numberPart):
				output = numberPart * unit[1]
				return output 
	#still try to convert it to a number even if it has no units at the end
	output = loadCSVFile.tryToConvertToNumber(toConvert)
	return output
	 


def test_convertTextToNumberIfPossibleAllowingUnits():
	assert convertTextToNumberIfPossibleAllowingUnits("100") == 100
	assert convertTextToNumberIfPossibleAllowingUnits("9231") == 9231
	assert convertTextToNumberIfPossibleAllowingUnits("9231.8") == 9231.8
	assert convertTextToNumberIfPossibleAllowingUnits("9 million") == 9000000
	assert convertTextToNumberIfPossibleAllowingUnits("9.2 million") == 9200000
	assert convertTextToNumberIfPossibleAllowingUnits("3 hundred") == 300
	assert convertTextToNumberIfPossibleAllowingUnits("32 thousand") == 32000
	assert convertTextToNumberIfPossibleAllowingUnits("6 million") == 6000000
	assert convertTextToNumberIfPossibleAllowingUnits("6.123 billion") == 6123000000
	assert convertTextToNumberIfPossibleAllowingUnits("6.123 trillion") == 6123000000000
	assert convertTextToNumberIfPossibleAllowingUnits("6.123 buffoon") == "6.123 buffoon"


if __name__ == "__main__":

	projectRoot = os.path.dirname(__file__)
	fileName = os.path.join(projectRoot, "raw_data/confidence interval trivia question data from Luke/OpenPhilanthropy_2_Final.csv")

	listOfRowDicts, headers = loadCSVFile.csvToListOfRowDictsAndHeaders(fileName)
	#print "listOfRowDicts", listOfRowDicts
	#print "Headers: ", headers
	newHeader = ["Question", "Answer", "Option 1", "Option 2", "Option 3", "Subcategory"]
	allQuestionData = []

	numDiscarded = 0

	for questionRowDict in listOfRowDicts:
		question = questionRowDict["QUESTION"].strip()

		#for some reason when the trivia data is written to regular csv file it has various weird characters converted from unicode!
		question = question.replace('\xd2', '"').replace('\xd3', '"').replace('“', '"').replace('”', '"')
		question = question.replace('\x8e', 'e').replace('é', 'e').replace('\xa3', 'L').replace('\xd0', 'D')
		question = question.replace('\xd6', "/").replace('\xca', ' ').replace('\xd5', "'").replace('\xd4', "'").replace('’', "'").replace('‘', "'")
		question = question.replace('\xa0', " ").replace('\xc2', ' ').replace('…', '...')

		try:
			question = question.encode('ascii', 'ignore')
		except:
			print "discarded non-ASCII question: " + str(question)
			numDiscarded += 1
			continue

		questionLower = question.lower()
		subcategory = questionRowDict["TOPIC"].strip()
		answerData = [questionRowDict[column] for column in ["CORRECT ANSWER", "ANSWER OPTION 1", "ANSWER OPTION 2", "ANSWER OPTION 3"]]

		#handle percent questions
		question = question.replace(" percentage ", " percentage (0-100) ")
		if (" percentage " in questionLower) and reduce(lambda result, answer: result and 0 <= answer <= 1, answerData):
			answerData = [int(answer * 100) for answer in answerData]

		if isinstance(answerData[0], (str, unicode)) and answerData[0][-1] == "%":
			#check if we need to make explicit that it's a percent
			if not ("percentage" in questionLower) and not ("percent" in questionLower) and not ("%" in questionLower):
				question += " (as a percent)"

		#handle commas in the number, and handle unit formatting at the end like 32 thousand or 3.7 million
		answerData = [0 if datum == 'never' else datum for datum in answerData]
		answerData = [convertTextToNumberIfPossibleAllowingUnits(datum) for datum in answerData]

		if isinstance(answerData[0], (str, unicode)) and answerData[0][0] == "$":
			print "discarded $ question: " + str(question)  + " -- " + str(answerData[0])
			numDiscarded += 1
			continue

		#first check for decade question
		if isDecadeNumber(answerData[0]) or ("which decade" in questionLower) or ("what decade" in questionLower):
			print "discarded decade question: " + str(question)  + " -- " + str(answerData[0])
			numDiscarded += 1
			continue

		#remove decade and century questions
		if  ("which century" in questionLower) or ("what century" in questionLower):
			print "discarded century question: " + str(question)  + "  -- " + str(answerData[0])
			numDiscarded += 1
			continue

		#remove time questions
		if  ("what time" in questionLower) or ("how long" in questionLower):
			print "discarded time question: " + str(question)  + "  -- " + str(answerData[0])
			numDiscarded += 1
			continue

		#remove math questions
		if  ("equals what number" in questionLower):
			print "discarded math question: " + str(question)  + "  -- " + str(answerData[0])
			numDiscarded += 1
			continue

		#remove rank or "place" quesitons, like what rank someone came in
		if isRankOrder(answerData[0]):
			print "discarded rank order question: " + str(question) + " -- " + str(answerData[0])
			numDiscarded += 1
			continue

		#only allow number answers
		if not loadCSVFile.isNumber(answerData[0]):
			print "discarded non number answer question: " + str(question)  + "  -- " + str(answerData[0])
			numDiscarded += 1
			continue


		#only allow positive answers (i.e. no negatives, no zero)
		if answerData[0] <= 0:
			print "discarded non positive answer question: " + str(question)  + " -- " + str(answerData[0])
			numDiscarded += 1
			continue

		#print "+accepted  question: " + str(question)  + "\nwith answer " + str(answer)

		correctAnswer, answerOption1, answerOption2, answerOption3 = answerData
		newQuestionData = [question, correctAnswer, answerOption1, answerOption2, answerOption3, subcategory]
		allQuestionData.append(newQuestionData)

	outputFileName = fileName.split(".")[-2] + "_clean_auto_generated" + ".csv"
	loadCSVFile.writeCSV(outputFileName, allQuestionData, header=newHeader)
	print "\n"
	print "Finished!"
	print "Discarded " + str(numDiscarded)
	print "\n"
	print "Wrote file: '" + str(outputFileName) + "' with " + str(len(allQuestionData)) + " questions!"
	print "\n"






