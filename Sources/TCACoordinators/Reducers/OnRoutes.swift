import ComposableArchitecture
import Foundation

struct OnRoutes<WrappedReducer: Reducer>: Reducer {
  typealias State = Route<WrappedReducer.State>
  typealias Action = WrappedReducer.Action

  let wrapped: WrappedReducer

  var body: some ReducerOf<Self> {
    Scope(state: \.screen, action: /.self) {
      wrapped
    }
  }
}
