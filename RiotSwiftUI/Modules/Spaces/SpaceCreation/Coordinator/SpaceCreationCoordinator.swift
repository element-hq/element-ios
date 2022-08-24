// File created from TemplateAdvancedRoomsExample
// $ createSwiftUITwoScreen.sh Spaces/SpaceCreation SpaceCreation SpaceCreationMenu SpaceCreationSettings
// File created from FlowTemplate
// $ createRootCoordinator.sh SpaceCreationCoordinator SpaceCreation
/*
 Copyright 2021 New Vector Ltd
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

import UIKit

@objcMembers
final class SpaceCreationCoordinator: Coordinator {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let parameters: SpaceCreationCoordinatorParameters
    
    private var navigationRouter: NavigationRouterType {
        return self.parameters.navigationRouter
    }
    
    private let spaceVisibilityMenuParameters: SpaceCreationMenuCoordinatorParameters
    private let spaceSharingTypeMenuParameters: SpaceCreationMenuCoordinatorParameters

    // MARK: Public
    
    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    
    var callback: ((SpaceCreationCoordinatorAction) -> Void)?
    
    // MARK: - Setup
    
    init(parameters: SpaceCreationCoordinatorParameters) {
        let title: String
        let message: String
        if let parentSpaceId = parameters.parentSpaceId, let parentSpaceName = parameters.session.spaceService.getSpace(withId: parentSpaceId)?.summary?.displayname {
            title = VectorL10n.spacesSubspaceCreationVisibilityTitle
            message = VectorL10n.spacesSubspaceCreationVisibilityMessage(parentSpaceName)
        } else {
            title = VectorL10n.spacesCreationVisibilityTitle
            message = VectorL10n.spacesCreationVisibilityMessage
        }

        self.parameters = parameters
        self.spaceVisibilityMenuParameters = SpaceCreationMenuCoordinatorParameters(
            session: parameters.session,
            creationParams: parameters.creationParameters,
            navTitle: VectorL10n.spacesCreateSpaceTitle,
            showBackButton: false,
            title: title,
            detail: message,
            options: [
                SpaceCreationMenuRoomOption(id: .publicSpace, icon: Asset.Images.spaceCreationPublic.image, title: VectorL10n.public, detail: VectorL10n.spacePublicJoinRuleDetail),
                SpaceCreationMenuRoomOption(id: .privateSpace, icon: Asset.Images.spaceCreationPrivate.image, title: VectorL10n.private, detail: VectorL10n.spacePrivateJoinRuleDetail)
            ]
        )
        
        self.spaceSharingTypeMenuParameters = SpaceCreationMenuCoordinatorParameters(
            session: parameters.session,
            creationParams: parameters.creationParameters,
            navTitle: nil,
            showBackButton: true,
            title: VectorL10n.spacesCreationSharingTypeTitle,
            detail: VectorL10n.spacesCreationSharingTypeMessage(parameters.creationParameters.name ?? ""),
            options: [
                SpaceCreationMenuRoomOption(id: .ownedPrivateSpace, icon: Asset.Images.tabPeople.image, title: VectorL10n.spacesCreationSharingTypeJustMeTitle, detail: VectorL10n.spacesCreationSharingTypeJustMeDetail),
                SpaceCreationMenuRoomOption(id: .sharedPrivateSpace, icon: Asset.Images.tabGroups.image, title: VectorL10n.spacesCreationSharingTypeMeAndTeammatesTitle, detail: VectorL10n.spacesCreationSharingTypeMeAndTeammatesDetail)
            ]
        )
    }
    
    // MARK: - Public
    
    func start() {
        MXLog.debug("[SpaceCreationCoordinator] did start.")
        
        Analytics.shared.trackScreen(.createSpace)
        
        let rootCoordinator = self.createMenuCoordinator(with: spaceVisibilityMenuParameters)
        rootCoordinator.start()
        
        self.add(childCoordinator: rootCoordinator)
        
        self.toPresentable().isModalInPresentation = true
        
        if self.navigationRouter.modules.isEmpty == false {
            self.navigationRouter.push(rootCoordinator, animated: true, popCompletion: { [weak self] in
                self?.remove(childCoordinator: rootCoordinator)
            })
        } else {
            self.navigationRouter.setRootModule(rootCoordinator) { [weak self] in
                self?.remove(childCoordinator: rootCoordinator)
            }
        }
    }
    
    func toPresentable() -> UIViewController {
        return self.navigationRouter.toPresentable()
    }
    
    // MARK: - Private
    
    func pushScreen(with coordinator: Coordinator & Presentable) {
        add(childCoordinator: coordinator)
        
        self.navigationRouter.push(coordinator, animated: true, popCompletion: { [weak self] in
            self?.remove(childCoordinator: coordinator)
        })
        
        coordinator.start()
    }

    private func createMenuCoordinator(with parameters: SpaceCreationMenuCoordinatorParameters) -> SpaceCreationMenuCoordinator {
        let coordinator: SpaceCreationMenuCoordinator = SpaceCreationMenuCoordinator(parameters: parameters)
        
        coordinator.callback = { [weak self] result in
            MXLog.debug("[SpaceCreationCoordinator] SpaceCreationMenuCoordinator did complete with result \(result).")
            guard let self = self else { return }
            switch result {
            case .didSelectOption(let optionId):
                switch optionId {
                case .privateSpace, .publicSpace:
                    self.pushScreen(with: self.createSettingsCoordinator())
                case .ownedPrivateSpace:
                    self.pushScreen(with: self.createRoomChooserCoordinator())
                case .sharedPrivateSpace:
                    self.pushScreen(with: self.createRoomsCoordinator())
                }
            case .cancel:
                self.cancel()
            case .back:
                self.back()
            }
        }
        return coordinator
    }
    
    private func createSettingsCoordinator() -> SpaceCreationSettingsCoordinator {
        let coordinator = SpaceCreationSettingsCoordinator(parameters: SpaceCreationSettingsCoordinatorParameters(session: parameters.session, creationParameters: parameters.creationParameters))
        coordinator.callback = { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .didSetupParameters:
                if self.parameters.creationParameters.isPublic {
                    self.pushScreen(with: self.createRoomsCoordinator())
                } else {
                    self.pushScreen(with: self.createMenuCoordinator(with: self.spaceSharingTypeMenuParameters))
                }
            case .cancel:
                self.cancel()
            case .back:
                self.back()
            }
        }
        return coordinator
    }
    
    private func createRoomsCoordinator() -> SpaceCreationRoomsCoordinator {
        let coordinator = SpaceCreationRoomsCoordinator(parameters: SpaceCreationRoomsCoordinatorParameters(session: parameters.session, creationParams: parameters.creationParameters))
        coordinator.callback = { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .didSetupRooms:
                if self.parameters.creationParameters.isPublic {
                    self.pushScreen(with: self.createPostProcessCoordinator())
                } else if self.parameters.creationParameters.isShared {
                    self.pushScreen(with: self.createEmailInvitesCoordinator())
                } else {
                    UILog.error("[SpaceCreationCoordinator] createRoomsCoordinator: should be public space or shared private space")
                }
            case .cancel:
                self.cancel()
            case .back:
                self.back()
            }
        }
        return coordinator
    }
    
    private func createEmailInvitesCoordinator() -> SpaceCreationEmailInvitesCoordinator {
        let coordinator = SpaceCreationEmailInvitesCoordinator(parameters: SpaceCreationEmailInvitesCoordinatorParameters(session: parameters.session, creationParams: parameters.creationParameters))
        coordinator.callback = { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .cancel:
                self.cancel()
            case .back:
                self.back()
            case .done:
                self.pushScreen(with: self.createPostProcessCoordinator())
            case .inviteByUsername:
                self.pushScreen(with: self.createPeopleChooserCoordinator())
            }
        }
        return coordinator
    }

    private func createPeopleChooserCoordinator() -> MatrixItemChooserCoordinator {
        let parameters = MatrixItemChooserCoordinatorParameters(
            session: parameters.session,
            title: VectorL10n.spacesCreationInviteByUsernameTitle,
            detail: VectorL10n.spacesCreationInviteByUsernameMessage,
            selectedItemsIds: parameters.creationParameters.userIdInvites,
            viewProvider: SpaceCreationMatrixItemChooserViewProvider(),
            itemsProcessor: SpaceCreationInviteUsersItemsProcessor(creationParams: parameters.creationParameters))
        let coordinator = MatrixItemChooserCoordinator(parameters: parameters)
        coordinator.completion = { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .cancel:
                self.cancel()
            case .back:
                self.back()
            case .done:
                self.pushScreen(with: self.createPostProcessCoordinator())
            }
        }
        return coordinator
    }

    private func createRoomChooserCoordinator() -> MatrixItemChooserCoordinator {
        let parameters = MatrixItemChooserCoordinatorParameters(
            session: parameters.session,
            title: VectorL10n.spacesCreationAddRoomsTitle,
            detail: VectorL10n.spacesCreationAddRoomsMessage,
            selectedItemsIds: parameters.creationParameters.addedRoomIds ?? [],
            viewProvider: SpaceCreationMatrixItemChooserViewProvider(),
            itemsProcessor: SpaceCreationAddRoomsItemsProcessor(creationParams: parameters.creationParameters))
        let coordinator = MatrixItemChooserCoordinator(parameters: parameters)
        coordinator.completion = { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .cancel:
                self.cancel()
            case .back:
                self.back()
            case .done:
                self.pushScreen(with: self.createPostProcessCoordinator())
            }
        }
        return coordinator
    }

    private func createPostProcessCoordinator() -> SpaceCreationPostProcessCoordinator {
        let coordinator = SpaceCreationPostProcessCoordinator(parameters: SpaceCreationPostProcessCoordinatorParameters(session: parameters.session, parentSpaceId: parameters.parentSpaceId, creationParams: parameters.creationParameters))
        coordinator.callback = { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .done(let spaceId):
                self.callback?(.done(spaceId))
            case .cancel:
                self.cancel()
            }
        }
        return coordinator
    }
    
    private func cancel() {
        if parameters.creationParameters.isModified {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            
            let alert = UIAlertController(title: VectorL10n.spacesCreationCancelTitle, message: VectorL10n.spacesCreationCancelMessage, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: VectorL10n.stop, style: .destructive, handler: { action in
                self.callback?(.cancel)
            }))
            alert.addAction(UIAlertAction(title: VectorL10n.continue, style: .cancel, handler: nil))
            navigationRouter.present(alert, animated: true)
        } else {
            self.callback?(.cancel)
        }
    }
    
    private func back() {
        navigationRouter.popModule(animated: true)
    }
}
