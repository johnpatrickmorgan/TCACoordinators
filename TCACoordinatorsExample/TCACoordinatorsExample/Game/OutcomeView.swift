import Combine
import ComposableArchitecture
import SwiftUI
import UIKit

struct OutcomeView: View {
  let store: StoreOf<Outcome>

  var body: some View {
    WithPerceptionTracking {
      VStack {
        if let winner = store.winnerName {
          Text("Congratulations \(winner)!")
        } else {
          Text("The game ended in a draw")
        }
        Button("New game") {
          store.send(.newGameTapped)
        }
      }
      .navigationTitle("Game over")
      .navigationBarBackButtonHidden()
    }
  }
}

@Reducer
struct Outcome {
  @ObservableState
  struct State: Hashable {
    let id = UUID()
    var winner: Player?
    var oPlayerName: String
    var xPlayerName: String

    var winnerName: String? {
      guard let winner else { return nil }
      return winner == .x ? xPlayerName : oPlayerName
    }
  }

  enum Action: Equatable {
    case newGameTapped
  }
}
