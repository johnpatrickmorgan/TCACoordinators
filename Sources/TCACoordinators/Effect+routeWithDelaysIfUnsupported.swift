import Combine
import ComposableArchitecture
import FlowStacks
import Foundation
import SwiftUI

public extension Effect where Output: IndexedRouterAction, Failure == Never {
  /// Allows arbitrary changes to be made to the routes collection, even if SwiftUI does not support such changes within a single
  /// state update. For example, SwiftUI only supports pushing, presenting or dismissing one screen at a time. Any changes can be
  /// made to the routes passed to the transform closure, and where those changes are not supported within a single update by
  /// SwiftUI, an Effect stream of smaller permissible updates will be returned, interspersed with sufficient delays.
  ///
  /// - Parameter routes: The routes in their current state.
  /// - Parameter transform: A closure transforming the routes into their new state.
  /// - Returns: An Effect stream of actions with incremental updates to routes over time. If the proposed change is supported
  ///   within a single update, the Effect stream will include only one element.
  static func routeWithDelaysIfUnsupported(_ routes: [Route<Output.Screen>], _ transform: (inout [Route<Output.Screen>]) -> Void) -> Self {
    var transformedRoutes = routes
    transform(&transformedRoutes)
    let steps = RouteSteps.calculateSteps(from: routes, to: transformedRoutes)
    return scheduledSteps(steps: steps)
      .map { Output.updateRoutes($0) }
      .eraseToEffect()
  }
}

public extension Effect where Output: IdentifiedRouterAction, Failure == Never {
  /// Allows arbitrary changes to be made to the routes collection, even if SwiftUI does not support such changes within a single
  /// state update. For example, SwiftUI only supports pushing, presenting or dismissing one screen at a time. Any changes can be
  /// made to the routes passed to the transform closure, and where those changes are not supported within a single update by
  /// SwiftUI, an Effect stream of smaller permissible updates will be returned, interspersed with sufficient delays.
  ///
  /// - Parameter routes: The routes in their current state.
  /// - Parameter transform: A closure transforming the routes into their new state.
  /// - Returns: An Effect stream of actions with incremental updates to routes over time. If the proposed change is supported
  ///   within a single update, the Effect stream will include only one element.
  static func routeWithDelaysIfUnsupported(_ routes: IdentifiedArrayOf<Route<Output.Screen>>, _ transform: (inout IdentifiedArrayOf<Route<Output.Screen>>) -> Void) -> Self {
    var transformedRoutes = routes
    transform(&transformedRoutes)
    let steps = RouteSteps.calculateSteps(from: Array(routes), to: Array(transformedRoutes))
    return scheduledSteps(steps: steps)
      .map { Output.updateRoutes(IdentifiedArray(uncheckedUniqueElements: $0)) }
      .eraseToEffect()
  }
}

/// Transforms a series of steps into an AnyPublisher of those steps, each one delayed in time.
func scheduledSteps<Screen>(steps: [[Route<Screen>]]) -> AnyPublisher<[Route<Screen>], Never> {
  guard let head = steps.first else {
    return Empty().eraseToAnyPublisher()
  }

  let timer = Just(Date())
    .append(Timer.publish(every: 0.65, on: .main, in: .default).autoconnect())
  let tail = Publishers.Zip(steps.dropFirst().publisher, timer)
    .map { $0.0 }
  return Just(head)
    .append(tail)
    .eraseToAnyPublisher()
}
