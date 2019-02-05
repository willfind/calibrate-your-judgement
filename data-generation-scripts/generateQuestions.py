import questionsCityPopulation
import questionsSimpleMath
import questionsScatterplotCorrelation
import questionsIRCTrivia
import questionsPolitifact
import questionsConfidenceInterval
#import random
#import numpy
#import imgur
import utilities
#import question
#import os


def generateUniqueQuestion(questionNumber, questionType, imageUploadClient=None):
	if questionNumber <= 0: raise Exception("questionNumber was " + str(questionNumber) + " but must be greater than or equal to 1")
	#set the random seed based on the question number so that the results don't depend on the order
	utilities.setRandomSeed(questionNumber)
	try:
		if questionType == "city population":
			return questionsCityPopulation.getQuestion(questionNumber=questionNumber)
		elif questionType == "simple math": #we've merged out two types of math problems into one question type
			return questionsSimpleMath.getQuestion(questionNumber=questionNumber)
		#elif questionType == "simple math A":
		#	question = questionsSimpleMath.getQuestion(questionNumber=questionNumber, mathQuestionType="A")
		#elif questionType == "simple math B":
		#	question = questionsSimpleMath.getQuestion(questionNumber=questionNumber, mathQuestionType="B")
		elif questionType == "scatterplot correlation":
			return questionsScatterplotCorrelation.getQuestion(questionNumber=questionNumber, imageUploadClient=imageUploadClient)
		elif questionType == "irc wiki trivia":
			return questionsIRCTrivia.getQuestion(questionNumber=questionNumber)
		elif questionType == "politifact":
			return questionsPolitifact.getQuestion(questionNumber=questionNumber)
		elif questionType == "confidence interval":
			return questionsConfidenceInterval.getQuestion(questionNumber=questionNumber)
		else: raise Exception("Unknown question type '" + questionType + "'")
	except utilities.OutOfQuestionsException:
		return None

	

	

#default imgur album
#http://imgur.com/a/tHLYL    which is correlation scatterplots test

if __name__ == "__main__":
	questionStartNum = 1
	numQuestionsPerCategory = 10000 #200 #20000 #200
	saveToDisk = True
	uploadImages = False

	questionTypesToGenerate = ["politifact", "city population", "simple math", "scatterplot correlation", "irc wiki trivia", "confidence interval"]
	#questionTypesToGenerate = ["confidence interval"]


	print "\nWill be generating questions of type: " + str(questionTypesToGenerate) + "\n"

	if uploadImages:
		imageUploadClient = utilities.configureImageUpload(numQuestionsPerCategory)
	else: imageUploadClient = None

	if not uploadImages:
		print "Images will NOT be uploaded - they must be uploaded seperately with another script."

	utilities.setRandomSeed(1)


	questionList = []
	for trialNum in xrange(numQuestionsPerCategory):
		questionNumber = trialNum + questionStartNum

		for questionType in questionTypesToGenerate:
			#print "questionType", questionType, "questionNumber", questionNumber
			curQuestion = generateUniqueQuestion(questionNumber, questionType, imageUploadClient=imageUploadClient) 
			
			#sometimes a given question number simply won't exist for a certain type of question (e.g. on politifact, there are some questions that are actually "Flip flops" instead)
			if curQuestion is None: 
				continue
				#raise Exception("Bad question, it was None")
			
			questionList.append(curQuestion)

			curQuestion.show()

			if saveToDisk: curQuestion.save()


print "\n\n"
print "Finished generating questions!"
print ""



