import ComposableArchitecture
import FlowStacks
import Foundation
import SwiftUI
  
extension Reducer where State: Identifiable {
  
  /// Lifts a screen reducer to one that operates on an `IdentifiedArray` of `Route<Screen>`s. The resulting reducer will
  /// update the routes whenever the user navigates back, e.g. by swiping.
  ///
  /// - Parameters:
  ///   - environment: A function that transforms `CoordinatorEnvironment` into `Environment`.
  /// - Returns: A reducer that works on `CoordinatorState`, `CoordinatorAction`, `CoordinatorEnvironment`.
  public func forEachIdentifiedRoute<
    CoordinatorState: IdentifiedRouterState,
    CoordinatorAction: IdentifiedRouterAction,
    CoordinatorEnvironment
  >(
    environment toLocalEnvironment: @escaping (CoordinatorEnvironment) -> Environment,
    file: StaticString = #fileID,
    line: UInt = #line
  ) -> Reducer<CoordinatorState, CoordinatorAction, CoordinatorEnvironment>
  where
  CoordinatorAction.ScreenAction == Action,
  CoordinatorAction.Screen == CoordinatorState.Screen,
  State == CoordinatorState.Screen
  {
    self
      .forEachIdentifiedRoute(
        state: \CoordinatorState.routes,
        action: /CoordinatorAction.routeAction,
        updateRoutes: /CoordinatorAction.updateRoutes,
        environment: toLocalEnvironment,
        file: file,
        line: line
      )
  }
  
  /// Lifts a screen reducer to one that operates on an `IdentifiedArray` of `Route<Screen>`s. The resulting reducer will
  /// update the routes whenever the user navigates back, e.g. by swiping.
  ///
  /// - Parameters:
  ///   - state: A key path that can get/set a collection of routes inside `CoordinatorState`.
  ///   - action: A case path that can extract/embed `(Screen.ID, Action)` from `CoordinatorAction`.
  ///   - updateRoutes: A case path that can update the routes as a `CoordinatorAction`.
  ///   - environment: A function that transforms `CoordinatorEnvironment` into `Environment`.
  /// - Returns: A reducer that works on `CoordinatorState`, `CoordinatorAction`, `CoordinatorEnvironment`.
  public func forEachIdentifiedRoute<CoordinatorState, CoordinatorAction, CoordinatorEnvironment>(
    state toLocalState: WritableKeyPath<CoordinatorState, IdentifiedArrayOf<Route<State>>>,
    action toLocalAction: CasePath<CoordinatorAction, (State.ID, Action)>,
    updateRoutes: CasePath<CoordinatorAction, IdentifiedArrayOf<Route<State>>>,
    environment toLocalEnvironment: @escaping (CoordinatorEnvironment) -> Environment,
    file: StaticString = #fileID,
    line: UInt = #line
  ) -> Reducer<CoordinatorState, CoordinatorAction, CoordinatorEnvironment>
  {
    self
      .onRoutes()
      .forEach(
        state: toLocalState,
        action: toLocalAction,
        environment: toLocalEnvironment,
        file: file,
        line: line
      )
      .updateScreensOnInteraction(
        updateRoutes: updateRoutes,
        state: toLocalState
      )
  }
}

extension Reducer {
  
  /// Lifts a Screen reducer to one that acts on Route<Screen>.
  /// - Returns: The new reducer.
  func onRoutes() -> Reducer<Route<State>, Action, Environment> {
    return Reducer<Route<State>, Action, Environment> { state, action, environment in
      self.run(&state.screen, action, environment)
    }
  }
  
  /// Ensures the routes are updated whenever the user navigates back, e.g. by swiping.
  /// - Returns: The new reducer.
  func updateScreensOnInteraction<Routes>(
    updateRoutes: CasePath<Action, Routes>,
    state toLocalState: WritableKeyPath<State, Routes>
  ) -> Reducer {
    return self.combined(with: Reducer { state, action, environment in
      if let routes = updateRoutes.extract(from: action) {
        state[keyPath: toLocalState] = routes
      }
      return .none
    })
  }
}
