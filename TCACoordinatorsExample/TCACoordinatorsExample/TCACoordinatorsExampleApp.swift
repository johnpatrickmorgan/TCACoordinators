import SwiftUI
import ComposableArchitecture
import TCACoordinators
import FlowStacks

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
    TabView {
        IndexedNavCoordinatorView(
          store: Store(
            initialState: .initialState,
            reducer: indexedNavCoordinatorReducer,
            environment: IndexedNavCoordinatorEnvironment()
          )
        ).tabItem { Text("Indexed") }
        IdentifiedCoordinatorView(
          store: Store(
            initialState: .initialState,
            reducer: identifiedCoordinatorReducer,
            environment: IdentifiedCoordinatorEnvironment()
          )
        ).tabItem { Text("Identified") }
    }
  }
}

enum MainTabCoordinatorAction {
  
  case identified(IdentifiedCoordinatorAction)
  case indexed(IndexedNavCoordinatorAction)
}

struct MainTabCoordinatorState: Equatable {
  
  static let initialState = MainTabCoordinatorState(
    identified: .initialState,
    indexed: .initialState
  )
  
  var identified: IdentifiedCoordinatorState
  var indexed: IndexedNavCoordinatorState
}

struct MainTabCoordinatorEnvironment {}

typealias MainTabCoordinatorReducer = Reducer<
  MainTabCoordinatorState, MainTabCoordinatorAction, MainTabCoordinatorEnvironment
>

let mainTabCoordinatorReducer: MainTabCoordinatorReducer = .combine(
  identifiedCoordinatorReducer
    .pullback(
      state: \MainTabCoordinatorState.identified,
      action: /MainTabCoordinatorAction.identified,
      environment: { _ in .init() }
    )
)
