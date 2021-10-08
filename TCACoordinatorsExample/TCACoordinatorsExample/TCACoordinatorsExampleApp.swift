import SwiftUI
import ComposableArchitecture
import TCACoordinators

@main
struct TCACoordinatorsExampleApp: App {

  var body: some Scene {
    WindowGroup {
      NavigationView {
        AppCoordinatorView(
          store: Store(
            initialState: .initialState,
            reducer: appCoordinatorReducer,
            environment: AppCoordinatorEnvironment()
          )
        )
//        IdentifiedAppCoordinatorView(
//          store: Store(
//            initialState: .initialState,
//            reducer: identifiedAppCoordinatorReducer,
//            environment: AppCoordinatorEnvironment()
//          )
//        )
      }
    }
  }
}

// AppCoordinator

struct AppCoordinatorView: View {

  let store: Store<AppCoordinatorState, AppCoordinatorAction>

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

enum AppCoordinatorAction: IndexedScreenCoordinatorAction {

  case screenAction(Int, action: ScreenAction)
  case updateScreens([ScreenState])
}

struct AppCoordinatorState: Equatable, IndexedScreenCoordinatorState {

  static let initialState = AppCoordinatorState(
    screens: [.home(.init())]
  )

  var screens: [ScreenState]
}

struct AppCoordinatorEnvironment {}

typealias AppCoordinatorReducer = Reducer<
  AppCoordinatorState, AppCoordinatorAction, AppCoordinatorEnvironment
>

let appCoordinatorReducer: AppCoordinatorReducer = screenReducer
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


// IdentifiedAppCoordinator

struct IdentifiedAppCoordinatorView: View {

  let store: Store<IdentifiedAppCoordinatorState, IdentifiedAppCoordinatorAction>

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

struct IdentifiedAppCoordinatorState: Equatable, IdentifiedScreenCoordinatorState {
  
  static let initialState = IdentifiedAppCoordinatorState(
    screens: [.home(.init())]
  )

  var screens: IdentifiedArrayOf<ScreenState>
}

enum IdentifiedAppCoordinatorAction: IdentifiedScreenCoordinatorAction {

  case screenAction(ScreenState.ID, action: ScreenAction)
  case updateScreens(IdentifiedArrayOf<ScreenState>)
}

typealias IdentifiedAppCoordinatorReducer = Reducer<
  IdentifiedAppCoordinatorState, IdentifiedAppCoordinatorAction, AppCoordinatorEnvironment
>

let identifiedAppCoordinatorReducer: IdentifiedAppCoordinatorReducer = screenReducer
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
