import Foundation

public protocol IndexedScreenCoordinatorAction {

  associatedtype ScreenState
  associatedtype ScreenAction

  /// Creates an action that allows screens to be updated whenever the user navigates back.
  /// - Returns: An `IndexedScreenCoordinatorAction`, usually a case in an enum.
  static func updateScreens(_ screens: [ScreenState]) -> Self

  /// Creates an action that allows the action for a specific screen to be dispatched to that screen's reducer.
  /// - Returns: An `IndexedScreenCoordinatorAction`, usually a case in an enum.
  static func screenAction(_ index: Int, action: ScreenAction) -> Self
}
