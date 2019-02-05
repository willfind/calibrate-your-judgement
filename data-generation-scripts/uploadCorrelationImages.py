import loadCSVFile
import utilities
import constants
import imgur
import os
import time
import random


if __name__ == "__main__":
	scatterplotCSVFileName = "scatterplot correlation.csv"
	SAVE_DIRECTORY = constants.SAVE_DIRECTORY
	scatterPlotFullPath = SAVE_DIRECTORY + os.sep + scatterplotCSVFileName

	listOfRowDicts, headers = loadCSVFile.csvToListOfRowDictsAndHeaders(scatterPlotFullPath, toPythonObjects=True)
	print "Loaded " + str(len(listOfRowDicts)) + " rows."
	maxUploads = 2*len(listOfRowDicts)
	#print "Will be potentially uploading as many as " + str(maxUploads) + " images."

	imageUploadClient = utilities.configureImageUpload(maxUploads)
	#from experiments imgur seems to allow 50 images to be uploaded in 40 minutes roughly?? So maybe we should only do one per minute
	secondsBetweenUploads = 90 #this is here to try to prevent imgur from telling us we exceeded the allowed rate limit
	randomSleepVariation = 10 #throw in some random variation so we don't seem too mechanical

	counter = 0
	for row in listOfRowDicts:
		counter += 1 
		didUpload = False
		#if the main question image isn't uploaded yet
		if row["imageFile"] != "" and row["imageURL"] == "":
			print "Uploading image " + str(counter) + " for file '" + str(row["imageFile"]) + "'..."
			didUpload = True
			row["imageURL"] = utilities.uploadImageFile(row["imageFile"], imageUploadClient)
			print "Upload complete, now at url: " + str(row["imageURL"])
			print ""
			if row["imageFile"] == row["explanationImageFile"]:
				row["explanationImageURL"] = row["imageURL"]
		#if the explanation image isn't uploaded yet
		if row["explanationImageFile"] != "" and row["explanationImageURL"] == "":
			print "Uploading explanation image " + str(counter) + " for file '" + str(row["explanationImageFile"]) + "'..."
			didUpload = True
			row["explanationImageURL"] = utilities.uploadImageFile(row["explanationImageFile"], imageUploadClient)
			print "Upload complete, now at url: " + str(row["explanationImageURL"])
			print ""
		totalSleepSecs = secondsBetweenUploads + random.gauss(0, randomSleepVariation)
		if totalSleepSecs < 0: totalSleepSecs = 0
		if didUpload and counter < len(listOfRowDicts): 
			print "Pausing for " + str(round(totalSleepSecs,1)) + " secs."
			time.sleep(totalSleepSecs)


	print "Replacing file '" + str(scatterPlotFullPath) + "'..."
	loadCSVFile.replaceCSV(scatterPlotFullPath, listOfRowDicts, header=headers)
	print "File replaced with new data!"

	print ""



