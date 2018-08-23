# InstaDB
This simple app allows one to upload photos from their iOS photo library to Dropbox, and view previously uploaded photos in an instagram like collection. Image size in the collection can be adjusted, and images can be deleted (both from the local collection and from Dropbox) by tapping on a photo and selecting "Delete".

Use of the app will require one to sign in using existing Dropbox cridentials, and will store all photos in their personal dropbox under the folder `/Apps/InstaDB/`. Images added to, or removed from this folder on Dropbox ouside the app will have a corresponding impact on the collection in the app, but may not show up until one performs a manual refresh (swipe down on the collection).

## Installation & Usage

1) Make a local clone of this repo
2) `pod install`
3) Make sure to open the `.xcworkspace` file in Xcode, not `.xcodeproj`
4) Build and Run
5) Sign in with Dropbox and begin managing and viewing photos
