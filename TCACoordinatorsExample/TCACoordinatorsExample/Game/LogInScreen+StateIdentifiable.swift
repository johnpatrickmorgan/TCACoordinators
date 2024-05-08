import Foundation

extension LogInScreen.State: Identifiable {
  var id: UUID {
    switch self {
    case let .welcome(state):
      state.id
    case let .logIn(state):
      state.id
    }
  }
}
