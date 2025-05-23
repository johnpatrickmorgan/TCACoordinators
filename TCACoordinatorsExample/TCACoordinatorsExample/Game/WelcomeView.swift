import ComposableArchitecture
import Foundation
import SwiftUI

struct WelcomeView: View {
  let store: StoreOf<Welcome>

  var body: some View {
    VStack {
      Text("Welcome").font(.headline)
      Button("Log in") {
        store.send(.logInTapped)
      }
    }
    .navigationTitle("Welcome")
  }
}

@Reducer
struct Welcome {
  struct State: Hashable {
    let id = UUID()
  }

  enum Action {
    case logInTapped
  }
}
