The `buildable` contains templates with source files that build.

The goal is to turn these templates as Xcode templates. They are part of the Riot project in order to ensure they build

# ScreenTemplate
This is the boilerplate to create a screen that follows the MVVM-C pattern within the Riot app.

To use it (before it becomes an Xcode template):

- `./createScreen.sh MyScreen [subFolder]`
- Import the created folder in the Xcode project

`subFolder` is an option subfolder under `Riot/Modules/`


# FlowCoordinatorTemplate
The boilerplate to create a root coordinator and its presenter bridge that can be used from Objective-C.
 
To use it (before it becomes an Xcode template):

- `./createFlowCoordinator.sh MyFlowCoordinator [subFolder]`
- Import the created folder in the Xcode project

`subFolder` is an option subfolder under `Riot/Modules/`