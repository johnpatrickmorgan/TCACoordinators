import ComposableArchitecture
import FlowStacks
import Foundation
import SwiftUI

extension PresentationStore
where
  ID == Int, CoordinatorAction: IndexedScreenCoordinatorAction,
  CoordinatorAction.ScreenState == ScreenState, CoordinatorAction.ScreenAction == ScreenAction,
  CoordinatorState: IndexedScreenCoordinatorState, CoordinatorState.Screen == ScreenState
{

  /// Convenience initializer for managing screens in an `Array` identified by index, where
  /// State and Action conform to the `IndexedScreenCoordinator...` protocols.
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
