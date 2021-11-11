import SwiftUI
import ComposableArchitecture
import TCACoordinators

@main
struct TCACoordinatorsExampleApp: App {
  
  var body: some Scene {
    WindowGroup {
      MainTabCoordinatorView(store: .init(
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
      NavigationView {
        IndexedNavCoordinatorView(
          store: Store(
            initialState: .initialState,
            reducer: indexedNavCoordinatorReducer,
            environment: IndexedNavCoordinatorEnvironment()
          )
        )
      }.tabItem { Text("Indexed") }
      NavigationView {
        IdentifiedNavCoordinatorView(
          store: Store(
            initialState: .initialState,
            reducer: identifiedNavCoordinatorReducer,
            environment: IndexedNavCoordinatorEnvironment()
          )
        )
      }.tabItem { Text("Identified") }
    }
  }
}

enum MainTabCoordinatorAction {
  
  case identified(IdentifiedNavCoordinatorAction)
  case indexed(IndexedNavCoordinatorAction)
}

struct MainTabCoordinatorState: Equatable {
  
  static let initialState = MainTabCoordinatorState(
    identified: .initialState,
    indexed: .initialState
  )
  
  var identified: IdentifiedNavCoordinatorState
  var indexed: IndexedNavCoordinatorState
}

struct MainTabCoordinatorEnvironment {}

typealias MainTabCoordinatorReducer = Reducer<
  MainTabCoordinatorState, MainTabCoordinatorAction, MainTabCoordinatorEnvironment
>

let mainTabCoordinatorReducer: MainTabCoordinatorReducer = .combine(
  identifiedNavCoordinatorReducer
    .pullback(
      state: \MainTabCoordinatorState.identified,
      action: /MainTabCoordinatorAction.identified,
      environment: { _ in .init() }
    )
)

// IndexedNavCoordinator

struct IndexedNavCoordinatorView: View {
  
  let store: Store<IndexedNavCoordinatorState, IndexedNavCoordinatorAction>
  
  var body: some View {
    NavigationStore(store: store) { scopedStore in
      SwitchStore(scopedStore) {
        CaseLet(
          state: /ScreenState.home,
          action: ScreenAction.home,
          then: HomeView.init
        )
        CaseLet(
          state: /ScreenState.numbersList,
          action: ScreenAction.numbersList,
          then: NumbersListView.init
        )
        CaseLet(
          state: /ScreenState.numberDetail,
          action: ScreenAction.numberDetail,
          then: NumberDetailView.init
        )
      }
    }
  }
}

enum IndexedNavCoordinatorAction: IndexedScreenCoordinatorAction {
  
  case screenAction(Int, action: ScreenAction)
  case updateScreens([ScreenState])
}

struct IndexedNavCoordinatorState: Equatable, IndexedScreenCoordinatorState {
  
  static let initialState = IndexedNavCoordinatorState(
    screens: [.home(.init())]
  )
  
  var screens: [ScreenState]
}

struct IndexedNavCoordinatorEnvironment {}

typealias IndexedNavCoordinatorReducer = Reducer<
  IndexedNavCoordinatorState, IndexedNavCoordinatorAction, IndexedNavCoordinatorEnvironment
>

let indexedNavCoordinatorReducer: IndexedNavCoordinatorReducer = screenReducer
  .forEachIndexedScreen(environment: { _ in .init() })
  .updateScreensOnInteraction()
  .combined(
    with: Reducer { state, action, environment in
      switch action {
      case .screenAction(_, .home(.startTapped)):
        state.push(.numbersList(.init(numbers: Array(0..<100))))
        
      case .screenAction(_, .numbersList(.numberSelected(let number))):
        state.push(.numberDetail(.init(number: number)))
        
      case .screenAction(_, .numberDetail(.showDouble(let number))):
        state.push(.numberDetail(.init(number: number * 2)))
        
      case .screenAction(_, .numberDetail(.popTapped)):
        state.pop()
        
      case .screenAction(_, .numberDetail(.popToNumbersList)):
        state.popTo(/ScreenState.numbersList)
        
      case .screenAction(_, .numberDetail(.popToRootTapped)):
        state.popToRoot()
        
      default:
        break
      }
      return .none
    }
  )
  .cancelEffectsOnDismiss()


// IdentifiedNavCoordinator

struct IdentifiedNavCoordinatorView: View {
  
  let store: Store<IdentifiedNavCoordinatorState, IdentifiedNavCoordinatorAction>
  
  var body: some View {
    NavigationStore(store: store) { scopedStore in
      SwitchStore(scopedStore) {
        CaseLet(
          state: /ScreenState.home,
          action: ScreenAction.home,
          then: HomeView.init
        )
        CaseLet(
          state: /ScreenState.numbersList,
          action: ScreenAction.numbersList,
          then: NumbersListView.init
        )
        CaseLet(
          state: /ScreenState.numberDetail,
          action: ScreenAction.numberDetail,
          then: NumberDetailView.init
        )
      }
    }
  }
}

struct IdentifiedNavCoordinatorState: Equatable, IdentifiedScreenCoordinatorState {
  
  static let initialState = IdentifiedNavCoordinatorState(
    screens: [.home(.init())]
  )
  
  var screens: IdentifiedArrayOf<ScreenState>
}

enum IdentifiedNavCoordinatorAction: IdentifiedScreenCoordinatorAction {
  
  case screenAction(ScreenState.ID, action: ScreenAction)
  case updateScreens(IdentifiedArrayOf<ScreenState>)
}

typealias IdentifiedNavCoordinatorReducer = Reducer<
  IdentifiedNavCoordinatorState, IdentifiedNavCoordinatorAction, IndexedNavCoordinatorEnvironment
>

let identifiedNavCoordinatorReducer: IdentifiedNavCoordinatorReducer = screenReducer
  .forEachIdentifiedScreen(environment: { _ in .init() })
  .updateScreensOnInteraction()
  .combined(
    with: Reducer { state, action, environment in
      switch action {
      case .screenAction(_, .home(.startTapped)):
        state.push(.numbersList(.init(numbers: Array(0..<100))))
        
      case .screenAction(_, .numbersList(.numberSelected(let number))):
        state.push(.numberDetail(.init(number: number)))
        
      case .screenAction(_, .numberDetail(.showDouble(let number))):
        state.push(.numberDetail(.init(number: number * 2)))
        
      case .screenAction(_, .numberDetail(.popTapped)):
        state.pop()
        
      case .screenAction(_, .numberDetail(.popToNumbersList)):
        state.popTo(/ScreenState.numbersList)
        
      case .screenAction(_, .numberDetail(.popToRootTapped)):
        state.popToRoot()
        
      default:
        break
      }
      return .none
    }
  )
  .cancelEffectsOnDismiss()

// Screen

enum ScreenAction {
  
  case home(HomeAction)
  case numbersList(NumbersListAction)
  case numberDetail(NumberDetailAction)
}

enum ScreenState: Equatable, Identifiable {
  
  case home(HomeState)
  case numbersList(NumbersListState)
  case numberDetail(NumberDetailState)
  
  var id: UUID {
    switch self {
    case .home(let state):
      return state.id
    case .numbersList(let state):
      return state.id
    case .numberDetail(let state):
      return state.id
    }
  }
}

struct ScreenEnvironment {}

let screenReducer = Reducer<ScreenState, ScreenAction, ScreenEnvironment>.combine(
  homeReducer
    .pullback(
      state: /ScreenState.home,
      action: /ScreenAction.home,
      environment: { _ in HomeEnvironment() }
    ),
  numbersListReducer
    .pullback(
      state: /ScreenState.numbersList,
      action: /ScreenAction.numbersList,
      environment: { _ in NumbersListEnvironment() }
    ),
  numberDetailReducer
    .pullback(
      state: /ScreenState.numberDetail,
      action: /ScreenAction.numberDetail,
      environment: { _ in NumberDetailEnvironment() }
    )
)

// Home

struct HomeView: View {
  
  let store: Store<HomeState, HomeAction>
  
  var body: some View {
    WithViewStore(store) { viewStore in
      VStack {
        Button("Start", action: {
          viewStore.send(.startTapped)
        })
      }
    }
    .navigationTitle("Home")
  }
}

enum HomeAction {
  
  case startTapped
}

struct HomeState: Equatable {
  
  let id = UUID()
}

struct HomeEnvironment {}

let homeReducer = Reducer<
  HomeState, HomeAction, HomeEnvironment
> { state, action, environment in
  return .none
}

// NumbersList

struct NumbersListView: View {
  
  let store: Store<NumbersListState, NumbersListAction>
  
  var body: some View {
    WithViewStore(store) { viewStore in
      List(viewStore.numbers, id: \.self) { number in
        Button(
          "\(number)",
          action: {
            viewStore.send(.numberSelected(number))
          })
      }
    }
    .navigationTitle("Numbers")
  }
}

enum NumbersListAction {
  
  case numberSelected(Int)
}

struct NumbersListState: Equatable {
  
  let id = UUID()
  let numbers: [Int]
}

struct NumbersListEnvironment {}

let numbersListReducer = Reducer<
  NumbersListState, NumbersListAction, NumbersListEnvironment
> { state, action, environment in
  return .none
}

// NumberDetail

struct NumberDetailView: View {
  
  let store: Store<NumberDetailState, NumberDetailAction>
  
  var body: some View {
    WithViewStore(store) { viewStore in
      VStack(spacing: 8.0) {
        Text("Number \(viewStore.number)")
        Button("Increment") {
          viewStore.send(.incrementTapped)
        }
        Button("Increment after delay") {
          viewStore.send(.incrementAfterDelayTapped)
        }
        Button("Show double") {
          viewStore.send(.showDouble(viewStore.number))
        }
        Button("Pop") {
          viewStore.send(.popTapped)
        }
        Button("Pop to root") {
          viewStore.send(.popToRootTapped)
        }
        Button("Pop to numbers list") {
          viewStore.send(.popToNumbersList)
        }
      }
      .navigationTitle("Number \(viewStore.number)")
    }
  }
}

enum NumberDetailAction {
  
  case popTapped
  case popToRootTapped
  case popToNumbersList
  case incrementAfterDelayTapped
  case incrementTapped
  case showDouble(Int)
}

struct NumberDetailState: Equatable {
  
  let id = UUID()
  var number: Int
}

struct NumberDetailEnvironment {}

let numberDetailReducer = Reducer<NumberDetailState, NumberDetailAction, NumberDetailEnvironment> {
  state, action, environment in
  switch action {
  case .popToRootTapped, .popTapped, .popToNumbersList, .showDouble:
    return .none
    
  case .incrementAfterDelayTapped:
    return Effect(value: NumberDetailAction.incrementTapped)
      .delay(for: 3.0, tolerance: nil, scheduler: DispatchQueue.main, options: nil)
      .setFailureType(to: Never.self)
      .eraseToEffect()
    
  case .incrementTapped:
    state.number += 1
    return .none
  }
}
