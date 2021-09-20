import ComposableArchitecture
import FlowStacks
import Foundation
import SwiftUI

/// PresentationStore manages a presentation flow of screens for use within a `PresentationView`.
public struct PresentationStore<
  CoordinatorState: Equatable, CoordinatorAction, ScreenState, ScreenAction, ID: Hashable,
  ScreenContent: View
>: View {

  let store: Store<CoordinatorState, CoordinatorAction>
  let screens: (CoordinatorState) -> [(ID, ScreenState)]
  let updateScreens: ([(ID, ScreenState)]) -> CoordinatorAction
  let action: (ID, ScreenAction) -> CoordinatorAction

  @ViewBuilder var screenContent: (Store<ScreenState, ScreenAction>) -> ScreenContent

  func scopedStore(id: ID, screenState: ScreenState) -> Store<ScreenState, ScreenAction> {
    store.scope(
      state: { _ in screenState },
      action: { action(id, $0) }
    )
  }

  public var body: some View {
    WithViewStore(store) { viewStore in
      PStack(
        viewStore.binding(
          get: screens,
          send: updateScreens
        ),
        buildView: { identifiedScreenState in
          let (id, screenState) = identifiedScreenState
          screenContent(scopedStore(id: id, screenState: screenState))
        }
      )
    }
  }
}

extension PresentationStore where ScreenState: Identifiable {

  /// Convenience initializer for managing screens in an `IdentifiedArray`.
  public init(
    store: Store<CoordinatorState, CoordinatorAction>,
    screens: @escaping (CoordinatorState) -> IdentifiedArray<ID, ScreenState>,
    updateScreens: @escaping (IdentifiedArray<ID, ScreenState>) -> CoordinatorAction,
    action: @escaping (ID, ScreenAction) -> CoordinatorAction,
    screenContent: @escaping (Store<ScreenState, ScreenAction>) -> ScreenContent
  ) where ScreenState.ID == ID {
    self.init(
      store: store,
      screens: { screens($0).map { ($0.id, $0) } },
      updateScreens: { updateScreens(IdentifiedArray(uniqueElements: $0.map { $0.1 })) },
      action: action,
      screenContent: screenContent
    )
  }
}

extension PresentationStore where ID == Int {

  /// Convenience initializer for managing screens in an `Array`,
  /// identified by index.
  public init(
    store: Store<CoordinatorState, CoordinatorAction>,
    screens: @escaping (CoordinatorState) -> [ScreenState],
    updateScreens: @escaping ([ScreenState]) -> CoordinatorAction,
    action: @escaping (Int, ScreenAction) -> CoordinatorAction,
    screenContent: @escaping (Store<ScreenState, ScreenAction>) -> ScreenContent
  ) {
    self.init(
      store: store,
      screens: { Array(screens($0).enumerated()).map { ($0, $1) } },
      updateScreens: { updateScreens($0.map { $0.1 }) },
      action: action,
      screenContent: screenContent
    )
  }
}
