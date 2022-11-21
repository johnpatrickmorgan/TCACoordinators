import ComposableArchitecture
import Foundation
import SwiftUI

struct Screen: ReducerProtocol {
  enum Action {
    case home(Home.Action)
    case numbersList(NumbersList.Action)
    case numberDetail(NumberDetail.Action)
  }

  enum State: Equatable, Identifiable {
    case home(Home.State)
    case numbersList(NumbersList.State)
    case numberDetail(NumberDetail.State)
    
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
    Scope(state: /State.home, action: /Action.home) {
      Home()
    }
    Scope(state: /State.numbersList, action: /Action.numbersList) {
      NumbersList()
    }
    Scope(state: /State.numberDetail, action: /Action.numberDetail) {
      NumberDetail()
    }
  }
}

// Home

struct HomeView: View {
  let store: Store<Home.State, Home.Action>
  
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

struct Home: ReducerProtocol {
  struct State: Equatable {
    let id = UUID()
  }

  enum Action {
    case startTapped
  }
  
  var body: some ReducerProtocol<State, Action> {
    EmptyReducer()
  }
}

// NumbersList

struct NumbersListView: View {
  let store: Store<NumbersList.State, NumbersList.Action>
  
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

struct NumbersList: ReducerProtocol {
  struct State: Equatable {
    let id = UUID()
    let numbers: [Int]
  }

  enum Action {
    case numberSelected(Int)
  }
  
  var body: some ReducerProtocol<State, Action> {
    EmptyReducer()
  }
}

// NumberDetail

struct NumberDetailView: View {
  let store: Store<NumberDetail.State, NumberDetail.Action>
  
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

struct NumberDetail: ReducerProtocol {
  struct State: Equatable {
    let id = UUID()
    var number: Int
  }

  enum Action {
    case goBackTapped
    case goBackToRootTapped
    case goBackToNumbersList
    case incrementAfterDelayTapped
    case incrementTapped
    case showDouble(Int)
  }

  var body: some ReducerProtocol<State, Action> {
    Reduce { state, action in
      switch action {
      case .goBackToRootTapped, .goBackTapped, .goBackToNumbersList, .showDouble:
        return .none
        
      case .incrementAfterDelayTapped:
        return Effect(value: NumberDetail.Action.incrementTapped)
          .delay(for: 3.0, tolerance: nil, scheduler: DispatchQueue.main, options: nil)
          .eraseToEffect()
        
      case .incrementTapped:
        state.number += 1
        return .none
      }
    }
  }
}
