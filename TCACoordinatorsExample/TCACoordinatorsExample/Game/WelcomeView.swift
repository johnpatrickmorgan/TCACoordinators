import ComposableArchitecture
import Foundation
import SwiftUI

struct WelcomeView: View {
  let store: Store<WelcomeState, WelcomeAction>

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

enum WelcomeAction {
  case logInTapped
}

struct WelcomeState: Equatable {
  let id = UUID()
}

struct WelcomeEnvironment {}

let welcomeReducer = Reducer<
  WelcomeState, WelcomeAction, WelcomeEnvironment
> { _, _, _ in
  .none
}
