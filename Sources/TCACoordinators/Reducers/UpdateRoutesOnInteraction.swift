import ComposableArchitecture
import Foundation

extension Reducer {
  @ReducerBuilder<State, Action>
  func updatingRoutesOnInteraction<Routes>(
    updateRoutes: CaseKeyPath<Action, Routes>,
    toLocalState: WritableKeyPath<State, Routes>
  ) -> some ReducerOf<Self> where Action: CasePathable {
    self
    UpdateRoutesOnInteraction(
      wrapped: self,
      updateRoutes: updateRoutes,
      toLocalState: toLocalState
    )
  }
}

struct UpdateRoutesOnInteraction<WrappedReducer: Reducer, Routes>: Reducer where WrappedReducer.Action: CasePathable {
  let wrapped: WrappedReducer
  let updateRoutes: CaseKeyPath<Action, Routes>
  let toLocalState: WritableKeyPath<State, Routes>

  var body: some ReducerOf<WrappedReducer> {
    Reduce { state, action in
      if let routes = action[case: updateRoutes] {
        state[keyPath: toLocalState] = routes
      }
      return .none
    }
  }
}
