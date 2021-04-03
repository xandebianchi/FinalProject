<!--
*** This is the Readme from SweetMagicalMusicBox!
-->

<!-- ABOUT THE PROJECT -->
## About The Project

The SweetMagicalMusicBox was designed to be a fun musical app with the following characteristics:
* Play musical notes of the simple musical scale where the sounds from the notes are randomically selected in the screen in some fixed positions. 
* The user can also record songs. 
* In the second screen the user can view the list all the songs recorded.
* We use FreeSounds to upload the songs recorded in the app and get information from this songs to share them to Facebook. FreeSounds is a Website to upload sounds and you have to have an account there and get credentials to be possible to upload songs through our app, it can be done manually or through our app.
* Also in the second screen the user can register and login into FreeSounds to upload the sounds.
* Finally in the second screen he can share the song link on Facebook or another places.

## A) User Experience 

### 1) Main screen (Sweet Magical Music Box)

#### Play musical notes

In the main screen we have musical notes on fixed positions. The notes are randomically selected from simple musical scale (DO-RE-MI-FA-SOL-LA-SI), and the user can play songs.

#### Record songs

The user can record songs using the record button on the footer. It's necessary to give a name for the song. The first time, the user will have to accept permission to use microphone to record the musical notes being played. After finish the melody, it's necessary to stop record and this will save the new song to a file. The name of the last song recorded will be presented on the footer, it's the current song and it's possible to play it.

#### Play current song

The current song is named on the footer and it is the last song recorded. It's possible to play it using the button on the footer. And also to stop it using the same button with stop icon on it.

#### Go to List of Songs

We have a button in the right of navigation bar to go to list of songs to play the songs, upload them to FreeSounds and share them.

### 2) Second Screen (Magical Songs)

In this screen the app presents a list all the songs recorded by the user. Every line on the list display the song name and have three buttons, one to play the song and stop it, one to upload the song into FreeSounds and one to share the song to Facebook or another place.
Also in this screen we have a Register and Login button in the right of navigation bar, used to register and login into FreeSounds to upload songs and get information from there.

#### Playing song from the list

Choose the song to be played and click in the play button (first button) on the selected line, also it's possible to stop it. 

#### Upload song from the list into FreeSounds

Choose the song to be upload into FreeSounds and click in the upload button (middle button) on the selected line. It's necessary to be logged in FreeSounds to use this function.

#### Sharing song from the list

Choose the song to be shared and click in the share button (third button) on the selected line. It's necessary to be logged in FreeSounds to use this function.

#### Register

To use Freesounds, you can have a previously account registered and requested access credentials through this link (https://freesound.org/apiv2/apply). Or you can do this through the app using the button Register in the right of navigation bar. 

To Register in FreeSounds through the app, click on Register button in the right of navigation bar and go to the Register Screen. There are instructions there and the steps must be followed. 
1) First, click on Step 1. It will send you to FreeSounds website. It's necessary to login to your acccount in FreeSounds or register to a new account if you don't have one. 
2) Second, login into FreeSounds using the same website. After login, it will be presented the Credentials Screen inside FreeSounds website. 
3) Third, if you don't have credentials to use FreeSounds, request the credentials giving a name and a description in the required fields and click on Request access credentials button. It will be generated a Client id and a Client secret/Api key in the same website.
4) Fourth, copy the Client id and click in the top to go back to SweetMagicalMusicBox. Paste the code in the first textbox from Step 1.
5) Fifth, Click on Step 2. It will send you again to FreeSounds website. Copy the Client secret/Api key and click in the top to go back to SweetMagicalMusicBox.
6) Seventh, paste the ClientSecret in the second textbox from Step 2.
7) Click in the button to Save the codes.
8) When return to second screen (Magical Songs), you will be asked to get Authorization Code from FreeSounds, click OK and go to FreeSounds website.
9) If a button appears to Authorize FreeSounds, click on it. When the Authorization Code appears, copy it and click in the top to go back to SweeetMagicalMusicBox.
10) Paste the code in the textbox and click in OK. There's also an exceptional option, and if you have problems to get the code click on it.

## B) Build and Run information

To use the app, it's just necessary to use a device and not the simulator, since it's not possible to have the microphone recording in the simulator and it's the basis of the app. All the other information to use the app is above in the User Experience section. 

## Built Using

* [Alamofire](https://github.com/Alamofire/Alamofire)
