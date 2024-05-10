extension Game.State {
  var gameBoard: Three<Three<String>> {
    board.map { $0.map { $0?.label ?? "" } }
  }

  var isGameEnabled: Bool {
    !board.hasWinner && !board.isFilled
  }

  var title: String {
    "\(currentPlayerName), place your \(currentPlayer.label)"
  }
}
