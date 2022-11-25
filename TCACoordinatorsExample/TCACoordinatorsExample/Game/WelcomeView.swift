import ComposableArchitecture
import Foundation
import SwiftUI

struct WelcomeView: View {
  let store: StoreOf<Welcome>

  var body: some View {
    WithViewStore(store) { viewStore in
      VStack {
        Text("Welcome").font(.headline)
        Button("Log in", action: {
          viewStore.send(.logInTapped)
        })
      }
    }
    .navigationTitle("Welcome")
  }
}

struct Welcome: ReducerProtocol {
  struct State: Equatable {
    let id = UUID()
  }

  enum Action {
    case logInTapped
  }

  var body: some ReducerProtocol<State, Action> {
    EmptyReducer()
  }
}
