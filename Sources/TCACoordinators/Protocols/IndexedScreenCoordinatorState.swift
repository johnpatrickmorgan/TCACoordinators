import Foundation

public protocol IndexedScreenCoordinatorState {
  associatedtype Screen

  /// An array of screens, identified by index, representing a navigation/presentation stack.
  var screens: [Screen] { get set }
}
