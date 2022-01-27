import ComposableArchitecture
import FlowStacks
import SwiftUI
import TCACoordinators

struct Settings: Equatable {
  var isFormal: Bool
  var exclamationCount: Int

  static let initial = Settings(isFormal: true, exclamationCount: 0)
}

enum ScreenIdentifier: Equatable {
  case greet(name: String)
  case editGreeting
}

struct GreetingCoordinatorView: View {
  let store: Store<GreetingCoordinatorState, GreetingCoordinatorAction>

  var body: some View {
    TCARouter(store) { screenIdentifier in
      SwitchStore(screenIdentifier) {
        CaseLet(
          state: /GreetingScreenState.greet,
          action: GreetingScreenAction.greet,
          then: GreetView.init
        )
        CaseLet(
          state: /GreetingScreenState.editGreeting,
          action: GreetingScreenAction.editGreeting,
          then: EditGreetingView.init
        )
      }
    }
  }
}

struct GreetingCoordinatorState: Equatable, IndexedRouterState {
  static let initialState = GreetingCoordinatorState(
    screenIdentifiers: [.root(.greet(name: "John"), embedInNavigationView: true)],
    settings: .initial
  )

  var screenIdentifiers: [Route<ScreenIdentifier>]
  var settings: Settings

  var routes: [Route<GreetingScreenState>] {
    get {
      screenIdentifiers.map {
        $0.map { screenIdentifier in
          switch screenIdentifier {
          case .greet(let name):
            return .greet(GreetState(name: name, settings: settings))
          case .editGreeting:
            return .editGreeting(EditGreetingState(settings: settings))
          }
        }
      }
    }
    set {
      screenIdentifiers = newValue.map {
        $0.map { route in
          switch route {
          case .greet(let state):
            return .greet(name: state.name)
          case .editGreeting(let state):
            settings = state.settings
            return .editGreeting
          }
        }
      }
    }
  }
}

enum GreetingCoordinatorAction: IndexedRouterAction {
  case routeAction(Int, action: GreetingScreenAction)
  case updateRoutes([Route<GreetingScreenState>])
}

struct GreetingCoordinatorEnvironment {}

typealias GreetingCoordinatorReducer = Reducer<
  GreetingCoordinatorState, GreetingCoordinatorAction, GreetingCoordinatorEnvironment
>

let greetingCoordinatorReducer: GreetingCoordinatorReducer = greetingScreenReducer
  .forEachIndexedRoute(environment: { _ in .init() })
  .withRouteReducer(Reducer { state, action, _ in
    switch action {
    case .routeAction(_, .greet(.editGreetingTapped)):
      state.screenIdentifiers.presentSheet(.editGreeting, embedInNavigationView: true)

    default:
      break
    }
    return .none
  }
  )

enum GreetingScreenAction {
  case greet(GreetAction)
  case editGreeting(EditGreetingAction)
}

enum GreetingScreenState: Equatable {
  case greet(GreetState)
  case editGreeting(EditGreetingState)
}

struct GreetingScreenEnvironment {}

let greetingScreenReducer = Reducer<GreetingScreenState, GreetingScreenAction, GreetingScreenEnvironment>.combine(
  greetReducer
    .pullback(
      state: /GreetingScreenState.greet,
      action: /GreetingScreenAction.greet,
      environment: { _ in GreetEnvironment() }
    ),
  editGreetingReducer
    .pullback(
      state: /GreetingScreenState.editGreeting,
      action: /GreetingScreenAction.editGreeting,
      environment: { _ in EditGreetingEnvironment() }
    )
)

// Greet

struct GreetView: View {
  let store: Store<GreetState, GreetAction>

  var body: some View {
    WithViewStore(store) { viewStore in
      let salutation = viewStore.settings.isFormal ? "Hello" : "Hi"
      let suffix = Array(repeating: "!", count: viewStore.settings.exclamationCount).joined()
      VStack(spacing: 8.0) {
        Text("\(salutation) \(viewStore.name)\(suffix)")
        Button("Edit greeting", action: {
          viewStore.send(.editGreetingTapped)
        })
      }.padding()
    }
    .navigationTitle("Greeting")
  }
}

enum GreetAction {
  case editGreetingTapped
}

struct GreetState: Equatable {
  var name: String
  var settings: Settings
}

struct GreetEnvironment {}

let greetReducer = Reducer<
  GreetState, GreetAction, GreetEnvironment
> { _, _, _ in
  .none
}

// EditGreeting

struct EditGreetingView: View {
  let store: Store<EditGreetingState, EditGreetingAction>

  var body: some View {
    WithViewStore(store) { viewStore in
      VStack(spacing: 8.0) {
        Toggle(
          "Formal",
          isOn: Binding(
            get: { viewStore.settings.isFormal },
            set: { viewStore.send(.setIsFormal($0)) }
          )
        )
        HStack {
          Stepper(
            "Exclamations: \(viewStore.settings.exclamationCount)",
            onIncrement: { viewStore.send(.incrementExclamationCount) },
            onDecrement: { viewStore.send(.decrementExclamationCount) }
          )
        }
      }
      .padding()
      .navigationTitle("Edit greeting")
    }
  }
}

enum EditGreetingAction {
  case setIsFormal(Bool)
  case incrementExclamationCount
  case decrementExclamationCount
}

struct EditGreetingState: Equatable {
  var settings: Settings
}

struct EditGreetingEnvironment {}

let editGreetingReducer = Reducer<EditGreetingState, EditGreetingAction, EditGreetingEnvironment> {
  state, action, _ in
  switch action {
  case .setIsFormal(let newValue):
    state.settings.isFormal = newValue
    return .none
  case .incrementExclamationCount:
    state.settings.exclamationCount += 1
    return .none
  case .decrementExclamationCount:
    guard state.settings.exclamationCount > 0 else { return .none }
    state.settings.exclamationCount -= 1
    return .none
  }
}
