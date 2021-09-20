import ComposableArchitecture
import FlowStacks
import Foundation
import SwiftUI

extension NavigationStore
where
  CoordinatorState: IdentifiedScreenCoordinatorState,
  CoordinatorAction: IdentifiedScreenCoordinatorAction, CoordinatorState.Screen == ScreenState,
  CoordinatorAction.ScreenState == ScreenState, CoordinatorAction.ScreenAction == ScreenAction,
  ScreenState.ID == ID
{

  /// Convenience initializer for managing screens in an `IdentifiedArray`, where State
  /// and Action conform to the `IdentifiedScreenCoordinator...` protocols.
  public init(
    store: Store<CoordinatorState, CoordinatorAction>,
    screenContent: @escaping (Store<ScreenState, ScreenAction>) -> ScreenContent
  ) {
    self.init(
      store: store,
      screens: { $0.screens },
      updateScreens: CoordinatorAction.updateScreens,
      action: CoordinatorAction.screenAction,
      screenContent: screenContent
    )
  }
}
