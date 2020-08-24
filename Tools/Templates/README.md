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
