import imgurUpload
import imgurAuth
import sys
import os


def allFilePathsInFolder(folderPath, allowedExtensions):
	if not os.path.exists(folderPath): raise Exception("The folder '" + folderPath +  "' does not exist!")
	filePaths = []
	for fileName in os.listdir(folderPath):
		for extension in allowedExtensions:
			if fileName.endswith(extension): 
				filePaths.append(os.path.join(folderPath, fileName))
				break
	return filePaths


def uploadAllImages(folderPath, album):
	filePaths = allFilePathsInFolder(folderPath, [".jpg", ".png", ".svg"])

	print "\nConnecting to imgur..."
	imgurClient = imgurAuth.authenticate()
	print "\n\nPreparing to upload " + str(len(filePaths)) + " files"
	print ""
	result = imgurAuth.get_input("Are you sure you want to upload " + str(len(filePaths)) + " images to imgur? ")
	if not (result in ["y", "Y", "yes", "Yes", "YES"]):
		print "Quitting..."
		sys.exit(0)

	filesUploaded = 0
	for filePath in filePaths:
		print "#" + str(filesUploaded) + " (" + str(round(100*filesUploaded/float(len(filePaths)),0)) + ")" + " uploading file " + str(filePath) + " to " + str(album)
		fileName = os.path.split(filePath)[1]
		image = imgurUpload.uploadImage(filePath, client=imgurClient, name=fileName, album=album)
		print "Uploaded image is: " + str(image)
		filesUploaded += 1

	print "\n\nSuccessfull uploaded " + str(filesUploaded) + " files"



if __name__ == "__main__":
	folderPath = "images"
	album = "tHLYL" #this is album "correlation scatterplots test"

	uploadAllImages(folderPath, album)