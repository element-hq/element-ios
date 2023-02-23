The `buildable` folder contains templates with source files that build.

The goal is to turn these templates as Xcode templates. They are part of the Riot project in order to ensure they build

# ScreenTemplate
This is the boilerplate to create a screen that follows the MVVM-C pattern used within the Element app.

To create a screen from this template (before it becomes an Xcode template):

- `./createScreen.sh ScreenFolder MyScreenName`
- Import the created folder in the Xcode project

This will create ScreenFolder within the Riot/Modules. Files inside will be named `MyScreenNameXxx`.


# SimpleScreenTemplate
This is the boilerplate to create a simple screen.

To create a screen from this template (before it becomes an Xcode template):

- `./createSimpleScreen.sh ScreenFolder MyScreenName`
- Import the created folder in the Xcode project

This will create ScreenFolder within the Riot/Modules. Files inside will be named `MyScreenNameXxx`.


# FlowCoordinatorTemplate
The boilerplate to create a root coordinator and its presenter bridge that can be used from Objective-C.
 
To use it (before it becomes an Xcode template):

- `./createRootCoordinator.sh Folder MyRootCoordinatorName [DefaultScreenName]`
- Import created files in the Xcode project


# SwiftUISimpleScreenTemplate
This is the boilerplate to create a simple SwiftUI screen including view model, screen coordinator, unit and UI tests. 
 
To create a screen from this template (before it becomes an Xcode template):

- `./createSwiftUISimpleScreen.sh ScreenFolder MyScreenName`
- Import created files in the Xcode project

This will create `ScreenFolder` within the `RiotSwiftUI/Modules`. Files inside will be named `MyScreenNameXxx`.


# SwiftUISingleScreenTempalte
This is the boilerplate to create a simple SwiftUI screen including view model, screen coordinator, service, unit and UI tests. 
 
To create a screen from this template (before it becomes an Xcode template):

- `./createSwiftUISingleScreen.sh ScreenFolder MyScreenName`
- Import created files in the Xcode project

This will create `ScreenFolder` within the `RiotSwiftUI/Modules`. Files inside will be named `MyScreenNameXxx`.


# SwiftUITwoScreenTemplate
This is the boilerplate to create two single SwiftUI screens (including view models, screen coordinators, services, unit and UI tests) and a flow coordinator. 
 
To create screens from this template (before it becomes an Xcode template):

- `./createSwiftUITwoScreen.sh TwoScreenFolder MyRootCoordinator FirstScreenName SecondScreenName`
- Import created files in the Xcode project

This will create `TwoScreenFolder` within the `RiotSwiftUI/Modules`.


# Usage example
Following commands:

```
./createScreen.sh MyFlowDir/MyFirstScreenDir MyFirstScreen
./createRootCoordinator.sh MyFlowDir MyFlow MyFirstScreen
```

generate in `Riot/Modules`:

```
Riot/Modules/MyFlowDir
├── MyFirstScreenDir
│   ├── MyFirstScreenCoordinator.swift
│   ├── MyFirstScreenCoordinatorType.swift
│   ├── MyFirstScreenViewAction.swift
│   ├── MyFirstScreenViewController.storyboard
│   ├── MyFirstScreenViewController.swift
│   ├── MyFirstScreenViewModel.swift
│   ├── MyFirstScreenViewModelType.swift
│   └── MyFirstScreenViewState.swift
├── MyFlowCoordinator.swift
├── MyFlowCoordinatorBridgePresenter.swift
└── MyFlowCoordinatorType.swift
```

The generated code is ready to use. The screen provided by `ScreenTemplate` can by displayed by:

```
MyFlowCoordinatorBridgePresenter *presenter = [[MyFlowCoordinatorBridgePresenter alloc] initWithSession:session];
[presenter presentFrom:self animated:YES];
```
