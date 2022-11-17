import ComposableArchitecture
import Foundation

struct OnRoutes<WrappedReducer: ReducerProtocol>: ReducerProtocol {
  typealias State = Route<WrappedReducer.State>
  typealias Action = WrappedReducer.Action

  let wrapped: WrappedReducer

  func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
    wrapped.reduce(into: &state.screen, action: action)
  }
}
