import ComposableArchitecture
import Foundation
import SwiftUI

@Reducer(state: .equatable)
enum Screen {
	case home(Home)
	case numbersList(NumbersList)
	case numberDetail(NumberDetail)
}

//@Reducer
//struct Screen: Reducer {
//  enum Action {
//    case home(Home.Action)
//    case numbersList(NumbersList.Action)
//    case numberDetail(NumberDetail.Action)
//  }
//
//  enum State: Equatable, Identifiable {
//    case home(Home.State)
//    case numbersList(NumbersList.State)
//    case numberDetail(NumberDetail.State)
//
//    var id: UUID {
//      switch self {
//      case .home(let state):
//        return state.id
//      case .numbersList(let state):
//        return state.id
//      case .numberDetail(let state):
//        return state.id
//      }
//    }
//  }
//
//  var body: some ReducerOf<Self> {
//    Scope(state: \.home, action: \.home) {
//      Home()
//    }
//    Scope(state: \.numbersList, action: \.numbersList) {
//      NumbersList()
//    }
//    Scope(state: \.numberDetail, action: \.numberDetail) {
//      NumberDetail()
//    }
//  }
//}

// Home

struct HomeView: View {
  let store: StoreOf<Home>

  var body: some View {
    VStack {
      Button("Start") {
        store.send(.startTapped)
      }
    }
    .navigationTitle("Home")
  }
}

struct Home: Reducer {
  struct State: Equatable {
    let id = UUID()
  }

  enum Action {
    case startTapped
  }

  var body: some ReducerOf<Self> {
    EmptyReducer()
  }
}

// NumbersList

struct NumbersListView: View {
  let store: StoreOf<NumbersList>

  var body: some View {
    WithViewStore(store, observe: \.numbers) { viewStore in
      List(viewStore.state, id: \.self) { number in
        Button(
          "\(number)",
          action: {
            viewStore.send(.numberSelected(number))
          }
        )
      }
    }
    .navigationTitle("Numbers")
  }
}

struct NumbersList: Reducer {
  struct State: Equatable {
    let id = UUID()
    let numbers: [Int]
  }

  enum Action {
    case numberSelected(Int)
  }

  var body: some ReducerOf<Self> {
    EmptyReducer()
  }
}

// NumberDetail

struct NumberDetailView: View {
  let store: StoreOf<NumberDetail>

  var body: some View {
    WithViewStore(store, observe: \.number) { viewStore in
      VStack(spacing: 8.0) {
        Text("Number \(viewStore.state)")
        Button("Increment") {
          viewStore.send(.incrementTapped)
        }
        Button("Increment after delay") {
          viewStore.send(.incrementAfterDelayTapped)
        }
        Button("Show double") {
          viewStore.send(.showDouble(viewStore.state))
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
      .navigationTitle("Number \(viewStore.state)")
    }
  }
}

@Reducer
struct NumberDetail {
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

  @Dependency(\.mainQueue) var mainQueue

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .goBackToRootTapped, .goBackTapped, .goBackToNumbersList, .showDouble:
        return .none

      case .incrementAfterDelayTapped:
        return .run { send in
          try await mainQueue.sleep(for: .seconds(3))
          await send(.incrementTapped)
        }

      case .incrementTapped:
        state.number += 1
        return .none
      }
    }
  }
}
