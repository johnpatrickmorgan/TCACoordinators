import ComposableArchitecture
import Foundation

extension ReducerProtocol {
  func updatingScreensOnInteraction<Routes>(updateRoutes: CasePath<Action, Routes>, toLocalState: WritableKeyPath<State, Routes>) -> some ReducerProtocol<State, Action> {
    CombineReducers {
      self
      UpdateScreensOnInteraction(
        wrapped: self,
        updateRoutes: updateRoutes,
        toLocalState: toLocalState
      )
    }
  }
}

struct UpdateScreensOnInteraction<WrappedReducer: ReducerProtocol, Routes>: ReducerProtocol {
  typealias State = WrappedReducer.State
  typealias Action = WrappedReducer.Action

  let wrapped: WrappedReducer
  let updateRoutes: CasePath<Action, Routes>
  let toLocalState: WritableKeyPath<State, Routes>

  func reduce(into state: inout WrappedReducer.State, action: WrappedReducer.Action) -> EffectTask<Action> {
    if let routes = updateRoutes.extract(from: action) {
      state[keyPath: toLocalState] = routes
    }
    return .none
  }
}
