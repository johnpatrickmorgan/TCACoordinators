import ComposableArchitecture
import Foundation

/// A protocol standardizing naming conventions for action types that represent screens
/// in an `IdentifiedArray`.
public protocol IdentifiedScreenCoordinatorAction {
  associatedtype ScreenState: Identifiable
  associatedtype ScreenAction

  /// Creates an action that allows screens to be updated whenever the user navigates back.
  /// - Returns: An `IdentifiedScreenCoordinatorAction`, usually a case in an enum.
  static func updateScreens(_ screens: IdentifiedArrayOf<ScreenState>) -> Self

  /// Creates an action that allows the action for a specific screen to be dispatched to that screen's reducer.
  /// - Returns: An `IdentifiedScreenCoordinatorAction`, usually a case in an enum.
  static func screenAction(_ id: ScreenState.ID, action: ScreenAction) -> Self
}
