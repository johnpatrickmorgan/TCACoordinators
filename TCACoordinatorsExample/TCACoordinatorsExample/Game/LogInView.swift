import ComposableArchitecture
import Foundation
import SwiftUI

struct LogInView: View {
  @State private var name = ""

  let store: StoreOf<LogIn>

  var body: some View {
    VStack {
      TextField("Enter name", text: $name)
        .padding(24)
      Button("Log in") {
        store.send(.logInTapped(name: name))
      }
      .disabled(name.isEmpty)
    }
    .navigationTitle("LogIn")
  }
}

@Reducer
struct LogIn {
  struct State: Equatable {
    let id = UUID()
  }

  enum Action {
    case logInTapped(name: String)
  }
}
