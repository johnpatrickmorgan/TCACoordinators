import ComposableArchitecture
import Foundation
import SwiftUI

@Reducer(state: .equatable)
enum Screen {
  case home(Home)
  case numbersList(NumbersList)
  case numberDetail(NumberDetail)
}

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

@Reducer
struct Home {
  struct State: Equatable {
    let id = UUID()
  }

  enum Action {
    case startTapped
  }
}

// NumbersList

struct NumbersListView: View {
  let store: StoreOf<NumbersList>

  var body: some View {
    WithPerceptionTracking {
      List(store.numbers, id: \.self) { number in
        Button(
          "\(number)",
          action: {
            store.send(.numberSelected(number))
          }
        )
      }
    }
    .navigationTitle("Numbers")
  }
}

@Reducer
struct NumbersList {
  @ObservableState
  struct State: Equatable {
    let id = UUID()
    let numbers: [Int]
  }

  enum Action {
    case numberSelected(Int)
  }
}

// NumberDetail

struct NumberDetailView: View {
  let store: StoreOf<NumberDetail>

  var body: some View {
    WithPerceptionTracking {
      VStack(spacing: 8.0) {
        Text("Number \(store.number)")
        Button("Increment") {
          store.send(.incrementTapped)
        }
        Button("Increment after delay") {
          store.send(.incrementAfterDelayTapped)
        }
        Button("Show double (\(store.number * 2))") {
          store.send(.showDouble(store.number))
        }
        Button("Go back") {
          store.send(.goBackTapped)
        }
        Button("Go back to root from \(store.number)") {
          store.send(.goBackToRootTapped)
        }
        Button("Go back to numbers list") {
          store.send(.goBackToNumbersList)
        }
      }
      .navigationTitle("Number \(store.number)")
    }
  }
}

@Reducer
struct NumberDetail {
  @ObservableState
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
