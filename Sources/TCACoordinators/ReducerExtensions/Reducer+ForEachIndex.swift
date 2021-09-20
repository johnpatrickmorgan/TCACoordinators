import ComposableArchitecture
import FlowStacks
import Foundation
import SwiftUI

extension Reducer {

  /// Transforms a reducer into one that acts on an array of states, identifying each
  /// by index. This uses a deprecated method, but it should be safe to use whenever the
  /// array is transformed only in index-stable ways, such as pushing and popping in a
  /// navigation stack.
  /// - Returns: A reducer that acts on an array of states.
  public func forEachIndex<GlobalState, GlobalAction, GlobalEnvironment>(
    state toLocalState: WritableKeyPath<GlobalState, [State]>,
    action toLocalAction: CasePath<GlobalAction, (Int, Action)>,
    environment toLocalEnvironment: @escaping (GlobalEnvironment) -> Environment,
    breakpointOnNil: Bool = true,
    file: StaticString = #fileID,
    line: UInt = #line
  ) -> Reducer<GlobalState, GlobalAction, GlobalEnvironment> {
    self.forEach(
      state: toLocalState,
      action: toLocalAction,
      environment: toLocalEnvironment,
      breakpointOnNil: breakpointOnNil,
      file: file,
      line: line
    )
  }
}

extension Reducer {

  public func forEachIndexedScreen<
    CoordinatorState: IndexedScreenCoordinatorState,
    CoordinatorAction: IndexedScreenCoordinatorAction, CoordinatorEnvironment
  >(
    environment toLocalEnvironment: @escaping (CoordinatorEnvironment) -> Environment,
    breakpointOnNil: Bool = true,
    file: StaticString = #fileID,
    line: UInt = #line
  ) -> Reducer<CoordinatorState, CoordinatorAction, CoordinatorEnvironment>
  where
    CoordinatorAction.ScreenAction == Action, CoordinatorAction.ScreenState == State,
    CoordinatorState.Screen == State
  {
    self.forEachIndex(
      state: \.screens,
      action: /CoordinatorAction.screenAction,
      environment: toLocalEnvironment,
      breakpointOnNil: breakpointOnNil,
      file: file,
      line: line
    )
  }
}

extension Reducer {

  public func forEachIdentifiedScreen<
    CoordinatorState: IdentifiedScreenCoordinatorState,
    CoordinatorAction: IdentifiedScreenCoordinatorAction, CoordinatorEnvironment
  >(
    environment toLocalEnvironment: @escaping (CoordinatorEnvironment) -> Environment,
    breakpointOnNil: Bool = true,
    file: StaticString = #fileID,
    line: UInt = #line
  ) -> Reducer<CoordinatorState, CoordinatorAction, CoordinatorEnvironment>
  where
    CoordinatorAction.ScreenAction == Action, CoordinatorAction.ScreenState == State,
    CoordinatorState.Screen == State
  {
    self.forEach(
      state: \.screens,
      action: /CoordinatorAction.screenAction,
      environment: toLocalEnvironment,
      breakpointOnNil: breakpointOnNil,
      file: file,
      line: line
    )
  }
}
