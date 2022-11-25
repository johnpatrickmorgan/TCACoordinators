import ComposableArchitecture
import Foundation
import SwiftUI

struct LogInView: View {
  @State private var name = ""

  let store: StoreOf<LogIn>

  var body: some View {
    WithViewStore(store) { viewStore in
      VStack {
        TextField("Enter name", text: $name)
          .padding(24)
        Button("Log in", action: {
          viewStore.send(.logInTapped(name: name))
        })
          .disabled(name.isEmpty)
      }
    }
    .navigationTitle("LogIn")
  }
}

struct LogIn: ReducerProtocol {
  struct State: Equatable {
    let id = UUID()
  }

  enum Action {
    case logInTapped(name: String)
  }

  var body: some ReducerProtocol<State, Action> {
    EmptyReducer()
  }
}
