import ComposableArchitecture
import Foundation

public protocol IdentifiedScreenCoordinatorState {
  associatedtype Screen: Identifiable

  /// An identified array of screens representing a navigation/presentation stack.
  var screens: IdentifiedArrayOf<Screen> { get set }
}
