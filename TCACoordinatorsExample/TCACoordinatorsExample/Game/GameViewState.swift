extension Game.State {
  var gameBoard: Three<Three<String>> {
    board.map { $0.map { $0?.label ?? "" } }
  }

  var isGameEnabled: Bool {
    !board.hasWinner && !board.isFilled
  }

  var isPlayAgainButtonHidden: Bool {
    !board.hasWinner && !board.isFilled
  }

  var title: String {
    if board.hasWinner {
      "Winner! Congrats \(currentPlayerName)"
    } else if board.isFilled {
      "Tied game!"
    } else {
      "\(currentPlayerName), place your \(currentPlayer.label)"
    }
  }
}
