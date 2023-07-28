import ComposableArchitecture
import Foundation

extension Reducer {
  @ReducerBuilder<State, Action>
	func updatingRoutesOnInteraction<Routes>(updateRoutes: CasePath<Action, Routes>, toLocalState: WritableKeyPath<State, Routes>) -> some ReducerOf<Self> {
    self
    UpdateRoutesOnInteraction(
      wrapped: self,
      updateRoutes: updateRoutes,
      toLocalState: toLocalState
    )
  }
}

struct UpdateRoutesOnInteraction<WrappedReducer: Reducer, Routes>: Reducer {
  let wrapped: WrappedReducer
  let updateRoutes: CasePath<Action, Routes>
  let toLocalState: WritableKeyPath<State, Routes>

	var body: some ReducerOf<WrappedReducer> {
		Reduce { state, action in
			if let routes = updateRoutes.extract(from: action) {
				state[keyPath: toLocalState] = routes
			}
			return .none
		}
	}
}
