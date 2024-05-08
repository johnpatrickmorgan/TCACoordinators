import ComposableArchitecture
import SwiftUI
import TCACoordinators

@main
struct TCACoordinatorsExampleApp: App {
  var body: some Scene {
    WindowGroup {
      MainTabCoordinatorView(
        store: Store(initialState: .initialState) {
          MainTabCoordinator()
        }
      )
    }
  }
}

// MainTabCoordinator

struct MainTabCoordinatorView: View {
  @Perception.Bindable var store: StoreOf<MainTabCoordinator>

  var body: some View {
    WithPerceptionTracking {
      TabView(selection: $store.selectedTab.sending(\.tabSelected)) {
        IndexedCoordinatorView(
          store: store.scope(
            state: \.indexed,
            action: \.indexed
          )
        )
        .tabItem { Text("Indexed") }
        .tag(MainTabCoordinator.Tab.indexed)

        IdentifiedCoordinatorView(
          store: store.scope(
            state: \.identified,
            action: \.identified
          )
        )
        .tabItem { Text("Identified") }
        .tag(MainTabCoordinator.Tab.identified)

        AppCoordinatorView(
          store: store.scope(
            state: \.app,
            action: \.app
          )
        )
        .tabItem { Text("Game") }
        .tag(MainTabCoordinator.Tab.app)

        FormAppCoordinatorView(
          store: store.scope(
            state: \.form,
            action: \.form
          )
        )
        .tabItem { Text("Form") }
        .tag(MainTabCoordinator.Tab.form)

      }.onOpenURL { _ in
        // In reality, the URL would be parsed into a Deeplink.
        let deeplink = MainTabCoordinator.Deeplink.identified(.showNumber(42))
        store.send(.deeplinkOpened(deeplink))
      }
    }
  }
}

@Reducer
struct MainTabCoordinator: Reducer {
  enum Tab: Hashable {
    case identified, indexed, app, form, deeplinkOpened
  }

  enum Deeplink {
    case identified(IdentifiedCoordinator.Deeplink)
  }

  enum Action {
    case identified(IdentifiedCoordinator.Action)
    case indexed(IndexedCoordinator.Action)
    case app(GameApp.Action)
    case form(FormAppCoordinator.Action)
    case deeplinkOpened(Deeplink)
    case tabSelected(Tab)
  }

  @ObservableState
  struct State: Equatable {
    static let initialState = State(
      identified: .initialState,
      indexed: .initialState,
      app: .initialState,
      form: .initialState,
      selectedTab: .app
    )

    var identified: IdentifiedCoordinator.State
    var indexed: IndexedCoordinator.State
    var app: GameApp.State
    var form: FormAppCoordinator.State

    var selectedTab: Tab
  }

  var body: some ReducerOf<Self> {
    Scope(state: \.indexed, action: \.indexed) {
      IndexedCoordinator()
    }
    Scope(state: \.identified, action: \.identified) {
      IdentifiedCoordinator()
    }
    Scope(state: \.app, action: \.app) {
      GameApp()
    }
    Scope(state: \.form, action: \.form) {
      FormAppCoordinator()
    }
    Reduce { state, action in
      switch action {
      case let .deeplinkOpened(.identified(.showNumber(number))):
        state.selectedTab = .identified
        if state.identified.routes.canPush == true {
          state.identified.routes.push(.numberDetail(.init(number: number)))
        } else {
          state.identified.routes.presentSheet(.numberDetail(.init(number: number)), embedInNavigationView: true)
        }
      case let .tabSelected(tab):
        state.selectedTab = tab
      default:
        break
      }
      return .none
    }
  }
}
