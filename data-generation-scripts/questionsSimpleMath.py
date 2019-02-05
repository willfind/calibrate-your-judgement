from __future__ import division 	#treat division as floating point
import random
import re
import utilities
import question

MIN_ALLOWED_ABS_VALUE = 0.01
MAX_ALLOWED_ABS_VALUE = 1000000


def getCorrectInequalityText(trueValue, comparisonValue):
	if trueValue > comparisonValue:
		#correctInequality = ">"
		return ",  which is greater than "
	elif trueValue == comparisonValue:
		#correctInequality = "="
		return ",  which is equal to "
	elif trueValue < comparisonValue:
		#correctInequality = "<"
		return ",  which is less than "
	else: raise Exception("Invalid comparison")


def getQuestion(questionNumber, mathQuestionType="any"):
	if mathQuestionType == "any":
		randNum = random.randint(0,2)
		if randNum == 0:
			return simpleMathQuestionA(questionNumber) #the simpler type 
		elif randNum == 1 or randNum == 2:
			return simpleMathQuestionB(questionNumber) #the more complex type
		else: raise Exception("Should never get here")
	elif mathQuestionType == "A":
		return simpleMathQuestionA(questionNumber)		 
	elif mathQuestionType == "B":
		return simpleMathQuestionB(questionNumber)
	else: raise Exception("Invalid math question type!")		


def simpleMathQuestionA(questionNumber):
	utilities.setRandomSeed(questionNumber)

	while True:
		v = randomParameters()
		verifyStringOfFormula(v) #check that our string representation hasn't failed
		equationStr = formulaString(v)
		trueValue = formulaCalculate(v)
		if trueValue > MIN_ALLOWED_ABS_VALUE and trueValue < MAX_ALLOWED_ABS_VALUE: break

	comparisonValue = generateComparisonValue(trueValue)
	comparisonWord, inequality, correctAnswer = utilities.pickComparisonDirection(trueValue, comparisonValue)
	difficulty = 1.0 / (abs(comparisonValue - trueValue+.00001)/(trueValue+1.0))

	questionText = equationStr + "   " + inequality + "   " + str(comparisonValue)

	correctInequaltiyText = getCorrectInequalityText(trueValue, comparisonValue)

	questionPieces = [equationStr, trueValue, inequality, comparisonValue]
	explanationText = str(equationStr) + "  =  " + utilities.numberToReasonableRoundedString(trueValue) + correctInequaltiyText + utilities.numberToReasonableRoundedString(comparisonValue)
	return question.Question(questionText=questionText, correctAnswer=correctAnswer, explanationText=explanationText, answerType="true-false", difficulty=difficulty, questionPieces=questionPieces, questionNumber=questionNumber, category="simple math", subCategory="A", preambleText="", answerOptions=["True", "False"], answerScale="", imageFile="", explanationImageFile="", imageUploadClient=None)

	#return question.Question(questionText=questionText, answer=answer, trueValue=trueValue, difficulty=difficulty, category="simple math A", part1=equationStr, part2=inequality, part3=comparisonValue)


def removeUnnecessaryParens(equationStr):
	#simplify so that expressions ((1)) becomes just (1)
	equationStr = re.sub("\(\((\d(\d)*)\)\)", "(\\1)", equationStr)
	#simplify so that expressions like (1) just become 1
	equationStr = re.sub("\((\d(\d)*)\)", "\\1", equationStr)
	#simplify so thate expressions like ((1 + 6)) just become (1 + 6)
	equationStr = re.sub("\(\((\d(\d)*\s*[+-/%^]\s*\d(\d)*)\)\)", "(\\1)", equationStr)
	return equationStr

def test_removeUnnecessaryParens():
	assert removeUnnecessaryParens("1+(3)+6") == "1+3+6"
	assert removeUnnecessaryParens("1+(3)+(6)") == "1+3+6"
	assert removeUnnecessaryParens("1+((3))+(6)") == "1+3+6"
	assert removeUnnecessaryParens("((5+6))") == "(5+6)"
	assert removeUnnecessaryParens("1+((3 + 1))+(6)") == "1+(3 + 1)+6"
	assert removeUnnecessaryParens("1+((3 + 1))+(6/5)") == "1+(3 + 1)+(6/5)"
	assert removeUnnecessaryParens("1+((3 + 1))+((6/5))") == "1+(3 + 1)+(6/5)"
	assert removeUnnecessaryParens("(6 * (7  +  ((3  +  1)) / 7))  -  7   <   53") == "(6 * (7  +  (3  +  1) / 7))  -  7   <   53"


def simpleMathQuestionB(questionNumber):
	utilities.setRandomSeed(questionNumber)
	numTerms = random.randint(2, 7)
	numParens = random.randint(0, numTerms-2)

	while True: #keep trying until we get one that doesn't have a numerical issue
		equationList, varCount, opCount = createEquationList(numTerms)
		equationList = insertParensIntoEquationList(equationList, numParens)

		fillInItems(equationList, "x", [str(i) for i in range(1, 8+1)])
		fillInItems(equationList, "op", ["  +  ", "  -  ", " * ", " / ", "^"], maxTimesAllowedHash={"^":1})

		equationStr = "".join(equationList)

		equationStr = removeUnnecessaryParens(equationStr)

		#compute the actual value of this expression!
		trueValue = None
		try:
			exec("trueValue = " + equationStr.replace("^", "**"))
		except OverflowError, err:
			print "overflow error since result was too big, trying again: " + str(err)
			continue
		except ZeroDivisionError, err:
			print "zero division error: " + str(err)
			continue
		except ValueError, err:
			print "value error: " + str(err)
			continue

		if abs(trueValue) < MIN_ALLOWED_ABS_VALUE: continue 
		if abs(trueValue) > MAX_ALLOWED_ABS_VALUE: continue

		#print "trueValue", trueValue
		break


	comparisonValue = generateComparisonValue(trueValue)
	comparisonWord, inequality, correctAnswer = utilities.pickComparisonDirection(trueValue, comparisonValue)
	difficulty = 1.0 / (abs(comparisonValue - trueValue+.00001)/(abs(trueValue)+1.0))

	questionText = equationStr + "   " + inequality + "   " + str(comparisonValue)

	#print "questionText: " + str(questionText)
	#print "processes questionText: " + str(removeUnnecessaryParens(questionText))
	#print ""

	correctInequaltiyText = getCorrectInequalityText(trueValue, comparisonValue)


	questionPieces = [equationStr, trueValue, inequality, comparisonValue]
	explanationText = str(equationStr) + "  =  " + utilities.numberToReasonableRoundedString(trueValue) + correctInequaltiyText + utilities.numberToReasonableRoundedString(comparisonValue)
	return question.Question(questionText=questionText, correctAnswer=correctAnswer, explanationText=explanationText, answerType="true-false", difficulty=difficulty, questionPieces=questionPieces, questionNumber=questionNumber, category="simple math", subCategory="B", preambleText="", answerOptions=[True, False], answerScale="", imageFile="", explanationImageFile="", imageUploadClient=None)


	#return question.Question(questionText=questionText, answer=answer, trueValue=trueValue, difficulty=difficulty, category="simple math B", part1=equationStr, part2=inequality, part3=comparisonValue)




def generateComparisonValue(trueValue):
	#i = 0
	while True:
		#multiplier = random.uniform(0.60, 1.0/0.60)
		multiplier = random.gauss(1.0, 0.30)
		if multiplier < 0: continue
		if trueValue > 1:
			comparisonValue = int(round(multiplier * trueValue))
		else:
			comparisonValue = round(multiplier * trueValue, 2)
		#print "comparisonValue", comparisonValue
		#i += 1
		if comparisonValue == 0 or sign(comparisonValue) != sign(trueValue): continue
		break
	return comparisonValue




def sign(x):
	if x > 0: return 1
	if x == 0: return 0
	if x < 0: return -1

def createEquationList(numTerms):
	"""create a list of terms for an equation, of the form
	x1 op1 x2 op2 x3 op3 ...
	"""
	equationList = []
	varCount = 0
	opCount = 0
	for i in xrange(numTerms-1):
		equationList.append("x" + str(varCount))
		varCount += 1
		equationList.append("op" + str(opCount))
		opCount += 1

	equationList.append("x" + str(varCount))
	varCount += 1
	return equationList, varCount, opCount


def insertParensIntoEquationList(equationList, numParens):
	"""randomly insert valid pairs of open and close parentheses into
	an equation list"""
	for parenNum in xrange(numParens):
		#find a position for the open paren that is just before a var (not an operator)
		while True:
			randomParenPos1 = random.randint(0, len(equationList)-3)
			if equationList[randomParenPos1][0] == "x": break

		equationList.insert(randomParenPos1, "(")

		#find a position for the close paren that is just after a var (not an operator)
		while True:
			randomParenPos2 = random.randint(randomParenPos1+3, len(equationList))
			if randomParenPos2 == len(equationList) or equationList[randomParenPos2][0] == "o": break
		equationList.insert(randomParenPos2, ")")
	return equationList


def fillInItems(itemList, startMatch, randReplacementList, maxTimesAllowedHash=None):
	if maxTimesAllowedHash == None: maxTimesAllowedHash = {}
	listOfMatchingItems = []
	timesChosen = {}
	for item in itemList:
		if item.startswith(startMatch):
			listOfMatchingItems.append(item)
	for item in listOfMatchingItems:
		while True: #choose a random item to do the replacement, but don't exceed maxTimesAllowedHash for each item chosen
			replacementItem = random.choice(randReplacementList)
			if not replacementItem in timesChosen: timesChosen[replacementItem] = 1
			else: timesChosen[replacementItem] += 1
			if (replacementItem in maxTimesAllowedHash) and (timesChosen[replacementItem] > maxTimesAllowedHash[replacementItem]):
				continue
			break

		replaceItem(item, replacementItem, itemList)


def replaceItem(toReplace, replaceWith, theList):
	for i in xrange(len(theList)):
		if theList[i] == toReplace:
			theList[i] = replaceWith




def randomParameters():
	v = startingParameters()
	minVars = 3
	maxVars = len(v)
	positionsToModify = range(0,len(v))
	numToModify = random.randint(minVars,maxVars)
	minValues = [0 ,-15 ,1 ,1 ,0, 0, 1, 1]
	maxValues = [25,15,10,3,10,10,10, 3]
	assert len(v) == len(minValues)
	assert len(v) == len(maxValues)
	while True:
		for i in xrange(numToModify):
			posToModify = positionsToModify[i]
			minVal = minValues[posToModify]
			maxVal = maxValues[posToModify]
			v[posToModify] = random.randint(minVal, maxVal)
		if isValidParameters(v): break
		v = startingParameters()
	return v

def startingParameters():
	#chosen because it gives the simplest formula
	return [0, 1, 1, 1, 0, 1, 1, 1]

def isValidParameters(v):
	if isAlmost(formulaCalculateDenominator(v), 0): return False
	return True

def formulaCalculate(v):
	#return (v[0] + v[1] * (v[2]**v[3])) / float(v[4] + v[5] * (v[6]**v[7]))
	return formulaCalculateNumerator(v) / float(formulaCalculateDenominator(v))

def formulaCalculateNumerator(v):
	return v[0] + v[1] * (v[2]**v[3])

def formulaCalculateDenominator(v):
	return v[4] + v[5] * (v[6]**v[7])

def monomialString(a,b,c,d):
	"""gives the strong for a formula of the form 
	
	a + b * (c**d) 

	"""
	# 0 + 1 * (1**d)
	if a == 0 and b == 1 and c == 1:
		return str(1)
	#0 + 1 * (c**1)
	elif a == 0 and b == 1 and d == 1:
		return str(c)
	# 0 + 1 * (c**d)
	elif a == 0 and b == 1:
		return str(c) + displayPiece("^", d)
	#0 + b * (1**d)
	elif a == 0 and c == 1:
		return str(b)
	#0 + b * (c**d)
	elif a == 0:
		return str(b) + " * " + str(c) + displayPiece("^", d)
	# a + 1 * (1**d)
	elif b == 1 and c==1:
		return str(a) + " + 1"
	#a + 1 * (c**1)
	elif b == 1 and d==1:
		return str(a) + " + " + str(c)
	#a + 1 * (c**d)
	elif b == 1:
		return str(a) + " + " + str(c) + displayPiece("^", d)
	#a + b * (1**d)
	elif c == 1:
		#return str(a) + " + " + str(b)
		return str(a) + handleSign("+", b)
	elif d == 1:
		#return str(a) + " + " + str(b) + " * " + str(c)
		return str(a) +  handleSign("+", b) + " * " + str(c)
	
	return str(a) + " + " + str(b) + " * " + str(c) + displayPiece("^", d)



def handleSign(op, val):
	if op == "+" and val >= 0:
		return " + " + str(val) 
	elif op == "+" and val < 0:
		return " - " + str(-val)
	elif op == "-" and val >= 0:
		return " - " + str(val)
	elif op == "-" and val < 0:
		return " + " + str(-val)


def formulaString(v):
	numeratorStr = monomialString(v[0], v[1], v[2], v[3])
	denomValue = formulaCalculateDenominator(v)
	denominatorStr = monomialString(v[4], v[5], v[6], v[7])
	if isAlmost(denomValue, 1): return numeratorStr
	if " + " in denominatorStr or " - " in denominatorStr or "/" in denominatorStr or "*" in denominatorStr or "^" in denominatorStr:
		return "(" + numeratorStr + ")" + " / (" + denominatorStr + ")"
	else:
		return "(" + numeratorStr + ")" + " / " + denominatorStr

def verifyStringOfFormula(v):
	"""convert it to a string then back again to check that our converstion to a string representation works properly.
	Throws an exception if the value changes during this process."""
	value = formulaCalculate(v)
	stringValue = stringToValue(formulaString(v))
	if isAlmost(value, stringValue): return True
	raise Exception("For parameters " + str(v) + " we have " + str(value) + " != " + str(string) + " = " + str(stringValue))

def isAlmost(val1, val2):
	if abs(val1 - val2) < 1E-8: return True
	return False

def stringToValue(string):
	string = string.replace("^", "**")
	string = re.sub("/\s(\d(\d)*)", "/ (\\1)", string) #put a paranthesis around a number to the right of /, so that  5 / 3 becomes 5 / (3) so that we can make it 5 / float(3)
	string = string.replace("/(", "/float(")
	string = string.replace("/ (", "/ float(")
	exec("resultVal = " + string)
	return resultVal

def displayPiece(op, val, string=None):
	"""returns a string for how to display a piece of a formula given by
	op val 
	in the formula, for instance
	+ 0  or  ^0.5
	string is the existing string representation of that part of the formula,
	if it already has one
	For instance, for + 7*3
	we could have:  op=+, val=21, string="7*3"
	"""
	if string == None: string = str(val)
	#if it's basically an integer, make it an actual integer
	if isAlmost(val, round(val)): val = int(round(val))
	if op == "+" or op == "-":
		if val == 0: return "" #don't show adding or subtracting 0
		if op == "+" and val < 0:
			return " " + str(op) + " - " + str(-val)
		if op == "-" and val < 0:
			return " " + str(op) + " + " + str(-val)
	elif op == "*" or op == "/":
		if val == 1: return "" #don't show multiply by 1
	elif op == "^":
		if val == 1: return "" #don't show raising to the power 1
		if isAlmost(val, 1.0/2.0): return "^(1/2)"
		if isAlmost(val, 1.0/3.0): return "^(1/3)"
		if isAlmost(val, 1.0/4.0): return "^(1/4)"
		if isAlmost(val, 1.0/5.0): return "^(1/5)"
		if isAlmost(val, 1.0/6.0): return "^(1/6)"
		if isAlmost(val, 1.0/7.0): return "^(1/7)"
		if isAlmost(val, 1.0/8.0): return "^(1/8)"
		if isAlmost(val, 1.0/9.0): return "^(1/9)"
		if val >= 0: 
			return str(op) + string #don't use a space with exponents
		else:
			return str(op) + "(" + string + ")"
	elif op == None:
		return string

	return " " + str(op) + " " + string



if __name__ == "__main__":
	questionStartNum = 1
	numQuestions = 5000
	mathQuestionType = "A"

	for trialNum in xrange(numQuestions):
		curQuestionNum = trialNum + questionStartNum
		curQuestion = getQuestion(questionNumber=curQuestionNum, mathQuestionType=mathQuestionType)
		curQuestion.show()




