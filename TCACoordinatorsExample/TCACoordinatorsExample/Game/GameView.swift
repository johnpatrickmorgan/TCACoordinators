import Combine
import ComposableArchitecture
import SwiftUI
import UIKit

// Adapted from: https://github.com/pointfreeco/swift-composable-architecture/tree/main/Examples/TicTacToe/tic-tac-toe/Sources/GameCore

struct GameView: UIViewControllerRepresentable {
  let store: StoreOf<Game>

  typealias UIViewControllerType = GameViewController

  func makeUIViewController(context: Context) -> GameViewController {
    GameViewController(store: self.store)
  }

  func updateUIViewController(_ uiViewController: GameViewController, context: Context) {}
}

final class GameViewController: UIViewController {
  let store: StoreOf<Game>
  let viewStore: ViewStore<ViewState, Game.Action>
  let _viewStore: ViewStore<Game.State, Game.Action>
  private var cancellables: Set<AnyCancellable> = []

  struct ViewState: Equatable {
    let board: Three<Three<String>>
    let isGameEnabled: Bool
    let isPlayAgainButtonHidden: Bool
    let title: String?

    init(state: Game.State) {
      self.board = state.board.map { $0.map { $0?.label ?? "" } }
      self.isGameEnabled = !state.board.hasWinner && !state.board.isFilled
      self.isPlayAgainButtonHidden = !state.board.hasWinner && !state.board.isFilled
      self.title =
        state.board.hasWinner
          ? "Winner! Congrats \(state.currentPlayerName)!"
          : state.board.isFilled
          ? "Tied game!"
          : "\(state.currentPlayerName), place your \(state.currentPlayer.label)"
    }
  }

  init(store: StoreOf<Game>) {
    self.store = store
    self.viewStore = ViewStore(store.scope(state: ViewState.init))
    self._viewStore = ViewStore(store)
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    self.navigationItem.title = "Tic-Tac-Toe"
    self.view.backgroundColor = .systemBackground

    self.navigationItem.leftBarButtonItem = UIBarButtonItem(
      title: "Quit",
      style: .done,
      target: self,
      action: #selector(self.quitButtonTapped)
    )

    let titleLabel = UILabel()
    titleLabel.textAlignment = .center

    let playAgainButton = UIButton(type: .system)
    playAgainButton.setTitle("Play again?", for: .normal)
    playAgainButton.addTarget(self, action: #selector(self.playAgainButtonTapped), for: .touchUpInside)

    let logOutButton = UIButton(type: .system)
    logOutButton.setTitle("Log out", for: .normal)
    logOutButton.addTarget(self, action: #selector(self.logOutButtonTapped), for: .touchUpInside)

    let titleStackView = UIStackView(arrangedSubviews: [titleLabel, playAgainButton, logOutButton])
    titleStackView.axis = .vertical
    titleStackView.spacing = 2

    let gridCell11 = UIButton()
    gridCell11.addTarget(self, action: #selector(self.gridCell11Tapped), for: .touchUpInside)
    let gridCell21 = UIButton()
    gridCell21.addTarget(self, action: #selector(self.gridCell21Tapped), for: .touchUpInside)
    let gridCell31 = UIButton()
    gridCell31.addTarget(self, action: #selector(self.gridCell31Tapped), for: .touchUpInside)
    let gridCell12 = UIButton()
    gridCell12.addTarget(self, action: #selector(self.gridCell12Tapped), for: .touchUpInside)
    let gridCell22 = UIButton()
    gridCell22.addTarget(self, action: #selector(self.gridCell22Tapped), for: .touchUpInside)
    let gridCell32 = UIButton()
    gridCell32.addTarget(self, action: #selector(self.gridCell32Tapped), for: .touchUpInside)
    let gridCell13 = UIButton()
    gridCell13.addTarget(self, action: #selector(self.gridCell13Tapped), for: .touchUpInside)
    let gridCell23 = UIButton()
    gridCell23.addTarget(self, action: #selector(self.gridCell23Tapped), for: .touchUpInside)
    let gridCell33 = UIButton()
    gridCell33.addTarget(self, action: #selector(self.gridCell33Tapped), for: .touchUpInside)

    let cells = [
      [gridCell11, gridCell12, gridCell13],
      [gridCell21, gridCell22, gridCell23],
      [gridCell31, gridCell32, gridCell33],
    ]

    let gameRow1StackView = UIStackView(arrangedSubviews: cells[0])
    gameRow1StackView.spacing = 6
    let gameRow2StackView = UIStackView(arrangedSubviews: cells[1])
    gameRow2StackView.spacing = 6
    let gameRow3StackView = UIStackView(arrangedSubviews: cells[2])
    gameRow3StackView.spacing = 6

    let gameStackView = UIStackView(arrangedSubviews: [
      gameRow1StackView,
      gameRow2StackView,
      gameRow3StackView,
    ])
    gameStackView.axis = .vertical
    gameStackView.spacing = 6

    let rootStackView = UIStackView(arrangedSubviews: [
      titleStackView,
      gameStackView,
    ])
    rootStackView.isLayoutMarginsRelativeArrangement = true
    rootStackView.layoutMargins = .init(top: 0, left: 32, bottom: 0, right: 32)
    rootStackView.translatesAutoresizingMaskIntoConstraints = false
    rootStackView.axis = .vertical
    rootStackView.spacing = 100

    self.view.addSubview(rootStackView)

    NSLayoutConstraint.activate([
      rootStackView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
      rootStackView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
      rootStackView.centerYAnchor.constraint(equalTo: self.view.centerYAnchor),
    ])

    gameStackView.arrangedSubviews
      .flatMap { view in (view as? UIStackView)?.arrangedSubviews ?? [] }
      .enumerated()
      .forEach { idx, cellView in
        cellView.backgroundColor = idx % 2 == 0 ? .darkGray : .lightGray
        NSLayoutConstraint.activate([
          cellView.widthAnchor.constraint(equalTo: cellView.heightAnchor),
        ])
      }

    self.viewStore.publisher.title
      .assign(to: \.text, on: titleLabel)
      .store(in: &self.cancellables)

    self.viewStore.publisher.isPlayAgainButtonHidden
      .assign(to: \.isHidden, on: playAgainButton)
      .store(in: &self.cancellables)

    self.viewStore.publisher.isPlayAgainButtonHidden
      .assign(to: \.isHidden, on: logOutButton)
      .store(in: &self.cancellables)

    self.viewStore.publisher
      .map(\.board, \.isGameEnabled)
      .removeDuplicates(by: ==)
      .sink { board, isGameEnabled in
        board.enumerated().forEach { rowIdx, row in
          row.enumerated().forEach { colIdx, label in
            let button = cells[rowIdx][colIdx]
            button.setTitle(label, for: .normal)
            button.isEnabled = isGameEnabled
          }
        }
      }
      .store(in: &self.cancellables)
  }

  @objc private func gridCell11Tapped() { self.viewStore.send(.cellTapped(row: 0, column: 0)) }
  @objc private func gridCell12Tapped() { self.viewStore.send(.cellTapped(row: 0, column: 1)) }
  @objc private func gridCell13Tapped() { self.viewStore.send(.cellTapped(row: 0, column: 2)) }
  @objc private func gridCell21Tapped() { self.viewStore.send(.cellTapped(row: 1, column: 0)) }
  @objc private func gridCell22Tapped() { self.viewStore.send(.cellTapped(row: 1, column: 1)) }
  @objc private func gridCell23Tapped() { self.viewStore.send(.cellTapped(row: 1, column: 2)) }
  @objc private func gridCell31Tapped() { self.viewStore.send(.cellTapped(row: 2, column: 0)) }
  @objc private func gridCell32Tapped() { self.viewStore.send(.cellTapped(row: 2, column: 1)) }
  @objc private func gridCell33Tapped() { self.viewStore.send(.cellTapped(row: 2, column: 2)) }

  @objc private func quitButtonTapped() {
    self.viewStore.send(.quitButtonTapped)
  }

  @objc private func playAgainButtonTapped() {
    self.viewStore.send(.playAgainButtonTapped)
  }

  @objc private func logOutButtonTapped() {
    self.viewStore.send(.logOutButtonTapped)
  }
}

struct Game: ReducerProtocol {
  struct State: Equatable {
    let id = UUID()
    var board: Three<Three<Player?>> = .empty
    var currentPlayer: Player = .x
    var oPlayerName: String
    var xPlayerName: String

    init(oPlayerName: String, xPlayerName: String) {
      self.oPlayerName = oPlayerName
      self.xPlayerName = xPlayerName
    }

    var currentPlayerName: String {
      switch self.currentPlayer {
      case .o: return self.oPlayerName
      case .x: return self.xPlayerName
      }
    }
  }

  enum Action: Equatable {
    case cellTapped(row: Int, column: Int)
    case playAgainButtonTapped
    case logOutButtonTapped
    case quitButtonTapped
  }

  var body: some ReducerProtocol<State, Action> {
    Reduce { state, action in
      switch action {
      case let .cellTapped(row, column):
        guard
          state.board[row][column] == nil,
          !state.board.hasWinner
        else { return .none }

        state.board[row][column] = state.currentPlayer

        if !state.board.hasWinner {
          state.currentPlayer.toggle()
        }

        return .none

      case .playAgainButtonTapped:
        state = Game.State(oPlayerName: state.oPlayerName, xPlayerName: state.xPlayerName)
        return .none

      case .quitButtonTapped, .logOutButtonTapped:
        return .none
      }
    }
  }
}

/// A collection of three elements.
struct Three<Element>: CustomStringConvertible {
  var first: Element
  var second: Element
  var third: Element

  init(_ first: Element, _ second: Element, _ third: Element) {
    self.first = first
    self.second = second
    self.third = third
  }

  func map<T>(_ transform: (Element) -> T) -> Three<T> {
    .init(transform(self.first), transform(self.second), transform(self.third))
  }

  var description: String {
    return "[\(self.first),\(self.second),\(self.third)]"
  }
}

extension Three: MutableCollection {
  subscript(offset: Int) -> Element {
    _read {
      switch offset {
      case 0: yield self.first
      case 1: yield self.second
      case 2: yield self.third
      default: fatalError()
      }
    }
    _modify {
      switch offset {
      case 0: yield &self.first
      case 1: yield &self.second
      case 2: yield &self.third
      default: fatalError()
      }
    }
  }

  var startIndex: Int { 0 }
  var endIndex: Int { 3 }
  func index(after i: Int) -> Int { i + 1 }
}

extension Three: RandomAccessCollection {}

extension Three: Equatable where Element: Equatable {}
extension Three: Hashable where Element: Hashable {}

enum Player: Equatable {
  case o
  case x

  mutating func toggle() {
    switch self {
    case .o: self = .x
    case .x: self = .o
    }
  }

  var label: String {
    switch self {
    case .o: return "⭕️"
    case .x: return "❌"
    }
  }
}

extension Three where Element == Three<Player?> {
  static let empty = Self(
    .init(nil, nil, nil),
    .init(nil, nil, nil),
    .init(nil, nil, nil)
  )

  var isFilled: Bool {
    self.allSatisfy { $0.allSatisfy { $0 != nil } }
  }

  var hasWinner: Bool {
    self.hasWin(.o) || self.hasWin(.x)
  }

  func hasWin(_ player: Player) -> Bool {
    let winConditions = [
      [0, 1, 2], [3, 4, 5], [6, 7, 8],
      [0, 3, 6], [1, 4, 7], [2, 5, 8],
      [0, 4, 8], [6, 4, 2],
    ]

    for condition in winConditions {
      let matches =
        condition
          .map { self[$0 % 3][$0 / 3] }
      let matchCount =
        matches
          .filter { $0 == player }
          .count

      if matchCount == 3 {
        return true
      }
    }
    return false
  }
}
