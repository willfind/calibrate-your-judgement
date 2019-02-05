import random
import numpy
import utilities
import pylab
import question
import os
import numpy
import constants

def cor(list1, list2):
	return numpy.corrcoef(list1, list2)[0, 1]


def getQuestion(questionNumber, imageUploadClient=None):
	utilities.setRandomSeed(questionNumber)
	minCorr=None
	maxCorr=None
	numPoints=None
	polyDegree=None
	tempNoise = 0.1 #0.1 #this will keep getting adjusted automatically
	correlationWindow = 0.05

	if polyDegree is None: 
			#make linear the most common, with 2nd degree being less common, and third degree even less common
			#this specifies the probaility of getting each
			polyDegree = numpy.random.choice([1,2,3], p=[0.57, 0.28, 0.15])
			#print "polyDegree", polyDegree
			#polyDegree = random.choice([1,2,3])
	if numPoints is None: 
		numPoints = random.randint(10, 100) #was 250 max

	while True:
		#if all info is None, let's generate it at random
		if minCorr is None and maxCorr is None:
			targetCorr = random.uniform(correlationWindow,1.0-correlationWindow)
			minCorr = targetCorr - correlationWindow
			maxCorr = targetCorr + correlationWindow
		vecX, vecY, correlation = randomCorrelatedVecs(numPoints=numPoints, polyDegree=polyDegree, noise=tempNoise)
		#print "polyDegree", polyDegree, "numPoints", numPoints, "minCorr", minCorr, "correlation", correlation, "maxCorr", maxCorr 
		if ((minCorr is None) or correlation >= minCorr) and ((maxCorr is None) or (correlation <= maxCorr)):
			break
		else:
			if correlation < minCorr: 
				if correlation > 0: tempNoise *= 0.9
				else: tempNoise *= 1.08
			if correlation > maxCorr: 
				if correlation > 0: tempNoise *= 1.08
				else: tempNoise *= 0.9
			#print "noise", noise, "corr", correlation

	
	trueValue = correlation

	minimumDifference = 0.05
	rangeAllowed = 0.46
	while True:
		multiplier = random.uniform(rangeAllowed, 1.0/rangeAllowed)
		comparisonValue = round(multiplier * trueValue,2)
		#print "trueValue", trueValue, "comparisonValue", comparisonValue
		if comparisonValue < 1 and ((abs(comparisonValue - trueValue) > minimumDifference) or (trueValue < minimumDifference)): break

	comparisonWord, inequality, correctAnswer = utilities.pickComparisonDirection(trueValue, comparisonValue)

	questionText = "The correlation is " + str(comparisonWord) + " than " + str(comparisonValue) 
	difficulty = 1.0 / (abs(comparisonValue - trueValue+.00001)/(trueValue+1.0))

	#a (extremely likely to be) unique code for this particular correlation question based on its data and comparison
	#code = utilities.hashCode([vecX, vecY, comparisonWord, comparisonValue])
	#imageFileName = "corr<" + str(code) + ">" + ".jpg"
	imageFileName = "corr" + str(questionNumber) + "" + ".jpg"
	#print "imageFileName", imageFileName
#	if not os.path.exists(constants.CORRELATION_IMAGE_SAVE_DIRECTORY):
#		utilities.forceMakeDirectory(constants.CORRELATION_IMAGE_SAVE_DIRECTORY)
#	fullImagePath = constants.CORRELATION_IMAGE_SAVE_DIRECTORY + os.sep + imageFileName
#	plotCorrelation(vecX, vecY, fileName=fullImagePath, show=False)
	xAndYAsString = turnXAndYToString(vecX, vecY, digits=1)
#	print "xAndYAsString: " + str(xAndYAsString)

	#questionPieces = [correlation, inequality, comparisonValue]
	questionPieces = xAndYAsString
	explanationText = "The correlation was " + str(round(correlation, 2))

	return question.Question(questionText=questionText, correctAnswer=correctAnswer, explanationText=explanationText, answerType="true-false", difficulty=difficulty, questionPieces=questionPieces, questionNumber=questionNumber, category="scatterplot correlation", subCategory="degree " + str(polyDegree), preambleText="", answerOptions=["True", "False"], answerScale="", imageFile='', explanationImageFile='', imageUploadClient=imageUploadClient)

	#return question.Question(questionText=questionText, answer=answer, trueValue=trueValue, difficulty=difficulty, category="scatterplot correlation", localImageFile=fullImagePath, imageUploadClient=imageUploadClient, part1="plot_correlation", part2=inequality, part3=comparisonValue)


def turnXAndYToString(vecX, vecY, digits):
	output = []
	for x, y in zip(vecX, vecY):
		#output.append("[" + str(round(x,digits)) + "," + str(round(y,digits)) + "]")
		output.append([round(x,digits), round(y,digits)])
	#return '"[' + ",".join(output) + ']"'
	return output


def plotCorrelation(vecX, vecY, show=False, fileName=None):
	pylab.figure()
	#print "plotting figure with data: " + str(zip(vecX, vecY))
	#print "\n"
	pylab.plot(vecX, vecY, ".")
	if fileName != None: 
		utilities.forceMakeDirectory(os.path.split(fileName)[0])
		pylab.savefig(fileName)
	if show: pylab.show()
	pylab.close()


def polynomialFunc(coefs):
	def polyFunc(val):
		degree = 0
		total = 0.0
		for degree, coef in enumerate(coefs):
			#print str(coef) +  "* x^" + str(degree)
			total += coef*(val**degree)
		return total
	return polyFunc

def testPolyFunc():
	func = polynomialFunc([1,2,3,5])
	assert func(7) == 1 + 2*7 + 3*(7**2) + 5*(7**3)

def randomPolynomialFunc(degree):
	coefs = randomNormalList(degree+1)
	return polynomialFunc(coefs)

def randomNormalList(dim):
	return [random.gauss(0,1) for i in xrange(dim)]

def randomCorrelatedVecs(numPoints, polyDegree, noise):
	vecX = randomNormalList(numPoints)
	polyFunc = randomPolynomialFunc(polyDegree)
	vecY = [polyFunc(val) + random.gauss(0,noise) for val in vecX]
	correlation = cor(vecX, vecY)
	return vecX, vecY, correlation


if __name__ == "__main__":
	questionStartNum = 1
	numQuestions = 5000

	for trialNum in xrange(numQuestions):
		curQuestionNum = trialNum + questionStartNum
		curQuestion = getQuestion(questionNumber=curQuestionNum)
		curQuestion.show()



