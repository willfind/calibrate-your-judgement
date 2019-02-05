import csv
import numpy
import datetime
import random
import os

def keepOnlySpecificColumns(listOfDicts, columnsToKeep):
	filteredListOfDicts = []
	for curDict in listOfDicts:
		newDict = {}
		for column in columnsToKeep:
			if column in curDict:
				newDict[column] = curDict[column]
			else:
				print "row " + str(curDict) + " is missing column " + str(column)
	filteredListOfDicts.append(newDict)
	return filteredListOfDicts

def csvToListOfRowDictsAndHeaders(fileName, toPythonObjects=True):
	listOfRows, headers = csvToListOfRowListsAndHeaders(fileName, toPythonObjects)
	listOfDicts = []
	for row in listOfRows:
		curDict = {}
		for key, value in zip(headers, row):
			curDict[key] = value
		listOfDicts.append(curDict)
	return listOfDicts, headers

def csvToListOfRowListsAndHeaders(fileName, toPythonObjects=True, commentCharacter="#"):
	"""a list of lists, with one sublist per row"""
	listOfLists = []
	headers = None
	foundNonComment = False
	with open(fileName, 'rU') as csvfile:
		reader = csv.reader(csvfile)
		for row in reader:
			if len(row) == 0: continue
			if (not foundNonComment) and row[0][0] == "#": continue
			foundNonComment = True
			if headers == None:
				headers = list(row)
				for i in xrange(len(headers)):
					headers[i] = headers[i].strip()
			else:
				row = list(row)
				if toPythonObjects:
					for i in xrange(len(row)):
						row[i] = tryToConvertToNumber(row[i])
				listOfLists.append(row)

	return listOfLists, headers

def csvToListOfColumnListsAndHeaders(fileName, toPythonObjects=True):
	"""a list of lists, with one sublist per column"""
	listOfDicts, headers = csvToListOfRowDictsAndHeaders(fileName, toPythonObjects)
	listOfColumnLists = []
	for key in headers:
		columnList = []
		for curDict in listOfDicts:
			columnList.append(curDict[key])
		listOfColumnLists.append(columnList)
	return listOfColumnLists, headers


def removeNonNumericalValues(values):
	newValues = []
	for value in values:
		value = tryToConvertToNumber(value)
		if isNumber(value):
			newValues.append(value)
	return newValues


def isNumber(value):
	if isinstance(value, (int, long, float, numpy.float)): return True
	return False

def tryToConvertToNumber(value):
	if isNumber(value): return value
	try:
		return int(value)
	except ValueError:
		pass
	try:
		return float(value)
	except ValueError:
		pass
	if value.count("-") == 3:
		pieces = value.split("-")
		if (len(pieces[0]) == 2 or len(pieces[0]) == 4) and len(pieces[1])<=2 and len(pieces[2])<=2:
			try:
				return datetime.date(year=int(pieces[0]), month=int(pieces[1]), day=int(pieces[2]))
			except ValueError:
				pass

	return value.strip()


import csv



def convertToStrList(inputList, lineSeperator="\n"):
	"converts the list of lists into a list of strings."
	toreturn = []
	for item in inputList:
		if type(item) in (list, tuple):
			tmp = map(lambda x: str(x), item)
			tmp = lineSeperator.join(tmp)
			toreturn.append(tmp)
		else:
			toreturn.append(str(item))
	return toreturn


def fileLastCharacter(fileName):
	with open(fileName, 'rb+') as f:
	    f.seek(-1,2)
	    return f.read()


def listOfDictsToListOfLists(listOfDicts, header, fillBlanksWith=""):
	output = [header]
	for curDict in listOfDicts:
		curRow = []
		for key in header:
			if key in curDict:
				curRow.append(curDict[key])
			else:
				curRow.append(fillBlanksWith) 
		output.append(curRow)
	return output

def testListOfDictsToListOfLists():
	listOfDicts = []
	listOfDicts.append({"a":3, "b":6, "d":7})
	listOfDicts.append({"c":4, "b":6, "d":7})
	listOfDicts.append({"a":1, "b":2, "c":3})
	listOfDicts.append({"a":1, "b":2, "c":3, "d":4})
	header = ["a", "b", "c", "d"]
	listOfLists = listOfDictsToListOfLists(listOfDicts, header)
	print "listOfLists", listOfLists
	assert listOfLists == [header, [3,6,"",7],["", 6, 4, 7], [1, 2, 3, ""], [1,2,3,4]]




def replaceCSV(fileName, listOfListsOrDicts, header=[], topComments = [], lineSeperator="\n"):
	"""replaces fileName with the data given, by renaming it, writing a new file, and then deleting the renamed one"""
	if not os.path.exists(fileName): raise Exception("Could not replace file '" + str(fileName) + "' because it doesn't exist.")
	tempName = fileName + "_renamed_" + str(random.uniform(0,1))[-8:]
	#rename the file so it isn't destroyed if failure occurs (we'll delete it in a moment)
	os.rename(fileName, tempName)
	writeCSV(fileName, listOfListsOrDicts, header=header, topComments=topComments, lineSeperator=lineSeperator, mode="write")	
	#remove the temorarily renamed old file
	os.remove(tempName)


def writeCSV(fileName, listOfListsOrDicts, header=[], topComments = [], lineSeperator="\n", mode="write"):
	"writes the listOfLists to the csv file. Also writes headers and toComments."
	if len(listOfListsOrDicts) == 0: raise Exception("No data given to writeCSV!")
	if isinstance(listOfListsOrDicts[0], dict): #if its a list of dicts, convert it to a list of lists
		if len(header) == 0: raise Exception("You cannot pass a list of dicts without including a header!")
		listOfListsOrDicts = listOfDictsToListOfLists(listOfListsOrDicts, header=header, fillBlanksWith="")

	if len(header) > 0 and listOfListsOrDicts[0] == header:
		listOfListsOrDicts = listOfListsOrDicts[1:]

	if mode == "write":
		f = open(fileName, "w")
	elif mode == "append":
		f = open(fileName, "a")
	else: raise Exception("invalid mode for writing to CSV")
	csvwriter = csv.writer(f)
	for item in topComments:
		csvwriter.writerow([str(item)])
	#if not len(topComments) == 0:
	#	csvwriter.writerow([LINE_SEPERATOR] *3)
	if len(header) != 0:
		newHeader = convertToStrList(header, lineSeperator=lineSeperator)
		csvwriter.writerow(newHeader)
	#if the file doesn't end in a new line character
	if mode == "append" and (not fileLastCharacter(fileName) in ["\n", "\r"]):
		csvwriter.writerow([]) #write a blank row
	for item in listOfListsOrDicts:
		newItem = convertToStrList(item, lineSeperator=lineSeperator)
		csvwriter.writerow(newItem)
	f.close()


