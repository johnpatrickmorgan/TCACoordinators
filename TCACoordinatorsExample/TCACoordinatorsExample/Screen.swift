import Foundation
import SwiftUI
import ComposableArchitecture

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
struct Screen: ReducerProtocol {
  enum Action {
    
    case home(HomeAction)
    case numbersList(NumbersListAction)
    case numberDetail(NumberDetailAction)
  }

  enum State: Equatable, Identifiable {
    
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
  
  var body: some ReducerProtocol<State, Action> {
    EmptyReducer()
      .ifCaseLet(/State.home, action: /Action.home) {
        Reduce(homeReducer, environment: .init())
      }
      .ifCaseLet(/State.numbersList, action: /Action.numbersList) {
        Reduce(numbersListReducer, environment: .init())
      }
      .ifCaseLet(/State.numberDetail, action: /Action.numberDetail) {
        Reduce(numberDetailReducer, environment: .init())
      }
  }
}

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
        Button("Go back") {
          viewStore.send(.goBackTapped)
        }
        Button("Go back to root") {
          viewStore.send(.goBackToRootTapped)
        }
        Button("Go back to numbers list") {
          viewStore.send(.goBackToNumbersList)
        }
      }
      .navigationTitle("Number \(viewStore.number)")
    }
  }
}

enum NumberDetailAction {
  
  case goBackTapped
  case goBackToRootTapped
  case goBackToNumbersList
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
  case .goBackToRootTapped, .goBackTapped, .goBackToNumbersList, .showDouble:
    return .none
    
  case .incrementAfterDelayTapped:
    return Effect(value: NumberDetailAction.incrementTapped)
      .delay(for: 3.0, tolerance: nil, scheduler: DispatchQueue.main, options: nil)
      .eraseToEffect()
    
  case .incrementTapped:
    state.number += 1
    return .none
  }
}

