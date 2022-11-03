import ComposableArchitecture
import FlowStacks
import Foundation
import SwiftUI

@available(
  *,
  deprecated,
  message:
    """
    'Reducer' has been deprecated in favor of 'ReducerProtocol'.
    See equivalent extensions on ReducerProtocol.
    """
)
extension Reducer {
  
  /// Lifts a screen reducer to one that operates on an `Array` of `Route<Screen>`s. The resulting reducer will
  /// update the routes whenever the user navigates back, e.g. by swiping.
  ///
  /// - Parameters:
  ///   - environment: A function that transforms `CoordinatorEnvironment` into `Environment`.
  /// - Returns: A reducer that works on `CoordinatorState`, `CoordinatorAction`, `CoordinatorEnvironment`.
  public func forEachIndexedRoute<
    CoordinatorState: IndexedRouterState,
    CoordinatorAction: IndexedRouterAction,
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
      .forEachIndexedRoute(
        state: \CoordinatorState.routes,
        action: /CoordinatorAction.routeAction,
        updateRoutes: /CoordinatorAction.updateRoutes,
        environment: toLocalEnvironment,
        file: file,
        line: line
      )
  }
  
  /// Lifts a screen reducer to one that operates on an `Array` of `Route<Screen>`s. The resulting reducer will
  /// update the routes whenever the user navigates back, e.g. by swiping.
  ///
  /// - Parameters:
  ///   - state: A key path that can get/set a collection of routes inside `CoordinatorState`.
  ///   - action: A case path that can extract/embed `(Array.Index, Action)` from `CoordinatorAction`.
  ///   - updateRoutes: A case path that can update the routes as a `CoordinatorAction`.
  ///   - environment: A function that transforms `CoordinatorEnvironment` into `Environment`.
  /// - Returns: A reducer that works on `CoordinatorState`, `CoordinatorAction`, `CoordinatorEnvironment`.
  public func forEachIndexedRoute<CoordinatorState, CoordinatorAction, CoordinatorEnvironment>(
    state toLocalState: WritableKeyPath<CoordinatorState, [Route<State>]>,
    action toLocalAction: CasePath<CoordinatorAction, (Int, Action)>,
    updateRoutes: CasePath<CoordinatorAction, [Route<State>]>,
    environment toLocalEnvironment: @escaping (CoordinatorEnvironment) -> Environment,
    file: StaticString = #fileID,
    line: UInt = #line
  ) -> Reducer<CoordinatorState, CoordinatorAction, CoordinatorEnvironment>
  {
    self
      .onRoutes()
      // This uses a deprecated method, but it is safe to use whenever the array is transformed only in
      // index-stable ways, such as pushing and popping in a navigation stack.
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
