import ComposableArchitecture
import Foundation
import SwiftUI

struct LogInView: View {
  @State private var name = ""

  let store: Store<LogInState, LogInAction>

  var body: some View {
    WithViewStore(store) { viewStore in
      VStack {
        TextField("Enter name", text: $name)
          .padding()
        Button("Log in", action: {
          viewStore.send(.logInTapped(name: name))
        })
          .disabled(name.isEmpty)
      }
    }
    .navigationTitle("LogIn")
  }
}

enum LogInAction {
  case logInTapped(name: String)
}

struct LogInState: Equatable {
  let id = UUID()
}

struct LogInEnvironment {}

let logInReducer = Reducer<
  LogInState, LogInAction, LogInEnvironment
> { _, _, _ in
  .none
}
