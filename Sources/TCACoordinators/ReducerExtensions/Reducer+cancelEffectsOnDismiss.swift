import ComposableArchitecture
import FlowStacks
import Foundation
import SwiftUI

extension Reducer {

  /// Transforms a reducer into one that cancels screen actions when that screen is no
  /// longer shown, identifying screens by their index.
  /// - Parameter getCoordinatorId: A closure that creates a stable identifier for the coordinator.
  /// - Parameter screens: A closure that accesses the coordinator's screens array.
  /// - Parameter screenAction: A case path to an action that dispatches screen actions to the correct screen.
  /// - Returns: A new `Reducer`.
  public func cancelEffectsOnDismiss<ScreenAction, ScreenState, ID: Hashable>(
    getCoordinatorId: @escaping (State, Environment) -> ID,
    screens: @escaping (State) -> [ScreenState], screenAction: CasePath<Action, (Int, ScreenAction)>
  ) -> Reducer {
    return Reducer { state, action, environment in
      let coordinatorId = getCoordinatorId(state, environment)

      let preScreens = screens(state)
      let effect = self.run(&state, action, environment)
      let postScreens = screens(state)

      var effects: [Effect<Action, Never>] = []

      if postScreens.count < preScreens.count {
        let dismissedIndexes = postScreens.count..<preScreens.count
        for dismissedIndex in dismissedIndexes {
          let identity = CancellationIdentity(
            coordinatorId: coordinatorId, screenId: dismissedIndex)
          effects.append(Effect<Action, Never>.cancel(id: AnyHashable(identity)))
        }
      }

      if let (index, _) = screenAction.extract(from: action) {
        let identity = CancellationIdentity(coordinatorId: coordinatorId, screenId: index)
        effects.append(effect.cancellable(id: AnyHashable(identity)))
      } else {
        effects.append(effect)
      }

      return Effect.merge(effects)
    }
  }

  /// Transforms a reducer into one that cancels screen actions when that screen is no
  /// longer shown, identifying screens by their index.
  /// - Parameter coordinatorUUID: A stable identifier for the coordinator.
  /// - Parameter screens: A closure that accesses the coordinator's screens array.
  /// - Parameter screenAction: A case path to an action that dispatches screen actions to the correct screen.
  /// - Returns: A new `Reducer`.
  public func cancelEffectsOnDismiss<ScreenAction, ScreenState>(
    coordinatorUUID: UUID = .init(), screens: @escaping (State) -> [ScreenState],
    screenAction: CasePath<Action, (Int, ScreenAction)>
  ) -> Reducer {
    return cancelEffectsOnDismiss(
      getCoordinatorId: { _, _ in coordinatorUUID }, screens: screens, screenAction: screenAction)
  }
}

extension Reducer {

  /// Transforms a reducer into one that cancels screen actions when that screen is no
  /// longer shown, identifiying screens by their id.
  /// - Parameter getCoordinatorId: A closure that creates a stable identifier for the coordinator.
  /// - Parameter screens: A closure that accesses the coordinator's screens `IdentifiedArray`.
  /// - Parameter screenAction: A case path to an action that dispatches screen actions to the correct screen.
  /// - Returns: A new `Reducer`.
  public func cancelEffectsOnDismiss<ScreenAction, ScreenState: Identifiable, ID: Hashable>(
    getCoordinatorId: @escaping (State, Environment) -> ID,
    screens: @escaping (State) -> IdentifiedArrayOf<ScreenState>,
    screenAction: CasePath<Action, (ScreenState.ID, ScreenAction)>
  ) -> Reducer {
    return Reducer { state, action, environment in
      let coordinatorId = getCoordinatorId(state, environment)

      let preScreens = screens(state)
      let effect = self.run(&state, action, environment)
      let postScreens = screens(state)

      var effects: [Effect<Action, Never>] = []

      let preScreenIds = Set(preScreens.map(\.id))
      let postScreenIds = Set(postScreens.map(\.id))

      let dismissedScreenIds = preScreenIds.subtracting(postScreenIds)

      for dismissedScreenId in dismissedScreenIds {
        let identity = CancellationIdentity(
          coordinatorId: coordinatorId, screenId: dismissedScreenId)
        effects.append(Effect<Action, Never>.cancel(id: AnyHashable(identity)))
      }

      if let (screenId, _) = screenAction.extract(from: action) {
        let identity = CancellationIdentity(coordinatorId: coordinatorId, screenId: screenId)
        effects.append(effect.cancellable(id: AnyHashable(identity)))
      } else {
        effects.append(effect)
      }

      return Effect.merge(effects)
    }
  }

  /// Transforms a reducer into one that cancels screen actions when that screen is no
  /// longer shown, identifiying screens by their id.
  /// - Parameter coordinatorUUID: A stable identifier for the coordinator.
  /// - Parameter screens: A closure that accesses the coordinator's screens `IdentifiedArray`.
  /// - Parameter screenAction: A case path to an action that dispatches screen actions to the correct screen.
  /// - Returns: A new `Reducer`.
  public func cancelEffectsOnDismiss<ScreenAction, ScreenState: Identifiable>(
    coordinatorUUID: UUID = .init(), screens: @escaping (State) -> IdentifiedArrayOf<ScreenState>,
    screenAction: CasePath<Action, (ScreenState.ID, ScreenAction)>
  ) -> Reducer {
    return cancelEffectsOnDismiss(
      getCoordinatorId: { _, _ in coordinatorUUID }, screens: screens, screenAction: screenAction)
  }
}

extension Reducer
where
  Action: IndexedScreenCoordinatorAction, State: IndexedScreenCoordinatorState,
  Action.ScreenState == State.Screen
{

  /// Transforms a reducer into one that cancels screen actions when that screen is no
  /// longer shown, identifiying screens by their id. Action And State must conform to
  /// the `IndexedScreenCoordinator...` protocols.
  /// - Parameter coordinatorUUID: A closure that creates a stable identifier for the coordinator.
  /// - Returns: A new `Reducer`.
  public func cancelEffectsOnDismiss(coordinatorUUID: UUID = .init()) -> Reducer {
    return cancelEffectsOnDismiss(
      getCoordinatorId: { _, _ in coordinatorUUID },
      screens: { $0.screens },
      screenAction: /Action.screenAction
    )
  }
}

extension Reducer
where
  Action: IdentifiedScreenCoordinatorAction, State: IdentifiedScreenCoordinatorState,
  Action.ScreenState == State.Screen
{

  /// Transforms a reducer into one that cancels screen actions when that screen is no
  /// longer shown, identifiying screens by their id. Action And State must conform to
  /// the `IdentifiedScreenCoordinator...` protocols.
  /// - Parameter coordinatorUUID: A closure that creates a stable identifier for the coordinator.
  /// - Returns: A new `Reducer`.
  public func cancelEffectsOnDismiss(coordinatorUUID: UUID = .init()) -> Reducer {
    return cancelEffectsOnDismiss(
      getCoordinatorId: { _, _ in coordinatorUUID },
      screens: { $0.screens },
      screenAction: /Action.screenAction
    )
  }
}

/// Identifier for a particular screen within a particular coordinator.
private struct CancellationIdentity<CoordinatorID: Hashable, ScreenID: Hashable>: Hashable {

  let coordinatorId: CoordinatorID
  let screenId: ScreenID
}
