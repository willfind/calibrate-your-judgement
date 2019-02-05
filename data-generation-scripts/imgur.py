
"""
Notes about setting this up with imgur:
1. You have to go to the imgur API setup page and register the application2
2. When you do so, set it up wit OAuth 2 without a callback URL
3. I set this up with application name calibrationapp

https://api.imgur.com/oauth2
"""


from imgurpython import ImgurClient
import os
import utilities
import webbrowser

def authenticate():
	# Get client ID and secret from auth.ini
	config = get_config()
	config.read('auth.ini')
	client_id = config.get('credentials', 'client_id')
	client_secret = config.get('credentials', 'client_secret')

	client = ImgurClient(client_id, client_secret)

	# Authorization flow, pin example (see docs for other auth types)
	authorization_url = client.get_auth_url('pin')

	print("\n\nGo to the following URL: {0}".format(authorization_url))

	#open it up in a new web browser
	webbrowser.open(authorization_url, new=2, autoraise=True)
	
	# Read in the pin, handle Python 2 or 3 here.
	pin = utilities.get_input("Enter pin code: ")


	# ... redirect user to `authorization_url`, obtain pin (or code or token) ...
	credentials = client.authorize(pin, 'pin')
	client.set_user_auth(credentials['access_token'], credentials['refresh_token'])

	print("Authentication successful! Here are the details:")
	print("   Access token:  {0}".format(credentials['access_token']))
	print("   Refresh token: {0}".format(credentials['refresh_token']))

	return client


def uploadImage(fromPath, client, name, title=None, description=None, album=None):
	if title == None: title = name
	if not os.path.exists(fromPath): raise Exception("Cannot upload file '" + str(fromPath) + "' since it cannot be found.")

	# Here's the metadata for the upload. All of these are optional, including
	# this config dict itself.
	config = {
		'album': album,
		'name':  name,
		'title': title,
		'description': description
	}

	print("Uploading image " + str(name) + "... ")
	#note, if the server returns status code 429 we'll get a ImgurClientRateLimitError('Rate-limit exceeded!') error!
	imageInfoHash = client.upload_from_path(fromPath, config=config, anon=False)
	return imageInfoHash



def get_config():
	''' Create a config parser for reading INI files '''
	try:
		import ConfigParser
		return ConfigParser.ConfigParser()
	except:
		import configparser
		return configparser.ConfigParser()

# If you want to run this as a standalone script, so be it!
if __name__ == "__main__":
	authenticate()
