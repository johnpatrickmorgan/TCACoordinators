import ComposableArchitecture
import SwiftUI
import TCACoordinators

@main
struct TCACoordinatorsExampleApp: App {
  var body: some Scene {
    WindowGroup {
      MainTabCoordinatorView(
        store: .init(
          initialState: .initialState,
          reducer: mainTabCoordinatorReducer,
          environment: .init()
        )
      )
    }
  }
}

// MainTabCoordinator

struct MainTabCoordinatorView: View {
  let store: Store<MainTabCoordinatorState, MainTabCoordinatorAction>

  var body: some View {
    WithViewStore(store) { _ in
      TabView {
        IndexedCoordinatorView(
          store: store.scope(
            state: \MainTabCoordinatorState.indexed,
            action: MainTabCoordinatorAction.indexed
          )
        ).tabItem { Text("Indexed") }
        IdentifiedCoordinatorView(
          store: store.scope(
            state: \MainTabCoordinatorState.identified,
            action: MainTabCoordinatorAction.identified
          )
        ).tabItem { Text("Identified") }
        AppCoordinatorView(
          store: store.scope(
            state: \MainTabCoordinatorState.app,
            action: MainTabCoordinatorAction.app
          )
        ).tabItem { Text("App") }
      }
    }
  }
}

enum MainTabCoordinatorAction {
  case identified(IdentifiedCoordinatorAction)
  case indexed(IndexedCoordinatorAction)
  case app(AppCoordinatorAction)
}

struct MainTabCoordinatorState: Equatable {
  static let initialState = MainTabCoordinatorState(
    identified: .initialState,
    indexed: .initialState,
    app: .initialState
  )

  var identified: IdentifiedCoordinatorState
  var indexed: IndexedCoordinatorState
  var app: AppCoordinatorState
}

struct MainTabCoordinatorEnvironment {}

typealias MainTabCoordinatorReducer = Reducer<
  MainTabCoordinatorState, MainTabCoordinatorAction, MainTabCoordinatorEnvironment
>

let mainTabCoordinatorReducer: MainTabCoordinatorReducer = .combine(
  indexedCoordinatorReducer
    .pullback(
      state: \MainTabCoordinatorState.indexed,
      action: /MainTabCoordinatorAction.indexed,
      environment: { _ in .init() }
    ),
  identifiedCoordinatorReducer
    .pullback(
      state: \MainTabCoordinatorState.identified,
      action: /MainTabCoordinatorAction.identified,
      environment: { _ in .init() }
    ),
  appCoordinatorReducer
    .pullback(
      state: \MainTabCoordinatorState.app,
      action: /MainTabCoordinatorAction.app,
      environment: { _ in .init() }
    )
)
