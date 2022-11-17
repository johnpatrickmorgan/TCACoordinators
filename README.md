# TCACoordinators

_The coordinator pattern in the Composable Architecture_

`TCACoordinators` brings a flexible approach to navigation in SwiftUI using the [Composable Architecture (TCA)](https://github.com/pointfreeco/swift-composable-architecture). It allows you to manage complex navigation and presentation flows with a single piece of state, hoisted into a high-level coordinator. Using this pattern, you can write isolated screen features that have zero knowledge of their context within the navigation flow of an app. It achieves this by combining existing tools in TCA such as `Reducer.forEach`, `Reducer.pullback` and `SwitchStore` with [a novel approach to handling navigation in SwiftUI](https://github.com/johnpatrickmorgan/FlowStacks). 

You might like this library if you want to:

✅ Support deeplinks into _deeply_ nested navigation routes in your app.<br/>
✅ Easily reuse screen features within different navigation contexts.<br/>
✅ Easily go back to the root screen or a specific screen in the navigation stack.<br/>
✅ Keep all navigation logic in a single place.<br/>
✅ Break an app's navigation into multiple reusable coordinators and compose them together.<br/>


The library works by translating the array of screens into a hierarchy of nested `NavigationLink`s and presentation calls, so:

🚫 It does not rely on UIKit at all.<br/>
🚫 It does not use `AnyView` to type-erase screens.<br/>
🚫 It does not try to recreate `NavigationView` from scratch.<br/>


## Usage example

### Step 1 - Create a screen reducer

First, identify all possible screens that are part of the particular navigation flow you're modelling. The goal will be to combine their reducers into a single reducer - one that can drive the behaviour of any of those screens. Both the state and action types will be the sum of the individual screens' state and action types, and the reducer will combine each individual screens' reducers into one:

```swift
struct Screen: ReducerProtocol {
  enum Action {
    case home(Home.Action)
    case numbersList(NumbersList.Action)
    case numberDetail(NumberDetail.Action)
  }

  enum State: Equatable {
    case home(Home.State)
    case numbersList(NumbersList.State)
    case numberDetail(NumberDetail.State)
  }
  
  var body: some ReducerProtocol<State, Action> {
    EmptyReducer()
      .ifCaseLet(/State.home, action: /Action.home) {
        Home()
      }
      .ifCaseLet(/State.numbersList, action: /Action.numbersList) {
        NumbersList()
      }
      .ifCaseLet(/State.numberDetail, action: /Action.numberDetail) {
        NumberDetail()
      }
  }
}
```

### Step 2 - Create a coordinator reducer

The coordinator will manage multiple screens in a navigation flow. Its state should include an array of `Route<Screen.State>`s, representing the navigation stack: i.e. appending a new screen state to this array will trigger the corresponding screen to be pushed or presented. `Route` is an enum whose cases capture the screen state and how it should be shown, e.g. `case push(ScreenState)`. 

```swift
struct IndexedCoordinator: ReducerProtocol {
  struct CoordinatorState: Equatable, IndexedRouterState {
    var routes: [Route<ScreenState>]
  }
  ...
}
```

The coordinator's action should include two special cases. The first includes an index to allow screen actions to be dispatched to the correct screen in the routes array. The second allows the routes array to be updated automatically, e.g. when a user taps 'Back':

```swift
struct IndexedCoordinator: ReducerProtocol {
  ...
  enum CoordinatorAction: IndexedRouterAction {
    case routeAction(Int, action: ScreenAction)
    case updateRoutes([Route<ScreenState>])
  }
  ...
}
```

The coordinator's reducer defines any logic for presenting and dismissing screens, and uses `forEachRoute` to further apply the `Screen` reducer to each screen in the `routes` array:

```swift
struct IndexedCoordinator: ReducerProtocol {
  ...
  struct CancellationID {}
  
  var body: some ReducerProtocol<State, Action> {
    return Reduce<State, Action> { state, action in
      switch action {
      case .routeAction(_, .home(.startTapped)):
        state.routes.presentSheet(.numbersList(.init(numbers: Array(0 ..< 4))), embedInNavigationView: true)
        
      case .routeAction(_, .numbersList(.numberSelected(let number))):
        state.routes.push(.numberDetail(.init(number: number)))
        
      case .routeAction(_, .numberDetail(.showDouble(let number))):
        state.routes.presentSheet(.numberDetail(.init(number: number * 2)))
        
      case .routeAction(_, .numberDetail(.goBackTapped)):
        state.routes.goBack()
        
      case .routeAction(_, .numberDetail(.goBackToNumbersList)):
        return .routeWithDelaysIfUnsupported(state.routes) {
          $0.goBackTo(/Screen.State.numbersList)
        }
        
      case .routeAction(_, .numberDetail(.goBackToRootTapped)):
        return .routeWithDelaysIfUnsupported(state.routes) {
          $0.goBackToRoot()
        }
        
      default:
        break
      }
      return .none
    }.forEachRoute {
      Screen()
    }
  }
}
```

### Step 3 - Create a coordinator view

With that in place, a `CoordinatorView` can be created. It will use a `TCARouter`, which translates the array of routes into a nested list of screen views with invisible `NavigationLinks` and presentation calls, all configured with bindings that react appropriately to changes to the routes array. The `TCARouter` takes a closure that can create the view for any screen in the navigation flow. A `SwitchStore` is the natural way to achieve that, with a `CaseLet` for each of the possible screens:

```swift
struct CoordinatorView: View {
  let store: Store<Coordinator.State, Coordinator.Action>

  var body: some View {
    TCARouter(store) { screen in
      SwitchStore(screen) {
        CaseLet(
          state: /Screen.State.home,
          action: Screen.Action.home,
          then: HomeView.init
        )
        CaseLet(
          state: /Screen.State.numbersList,
          action: Screen.Action.numbersList,
          then: NumbersListView.init
        )
        CaseLet(
          state: /Screen.State.numberDetail,
          action: Screen.Action.numberDetail,
          then: NumberDetailView.init
        )
      }
    }
  }
}
```


## Convenience methods

The routes array can be managed using normal Array methods such as `append`, but a number of convenience methods are available for common transformations, such as:

| Method       | Effect                                            |
|--------------|---------------------------------------------------|
| push         | Pushes a new screen onto the stack.               |
| presentSheet | Presents a new screen as a sheet.†                |
| presentCover | Presents a new screen as a full-screen cover.†    |
| goBack       | Goes back one screen in the stack.                |
| goBackToRoot | Goes back to the very first screen in the stack.  |
| goBackTo     | Goes back to a specific screen in the stack.      |
| pop          | Pops the current screen if it was pushed.         |
| dismiss      | Dismisses the most recently presented screen.     |

† _Pass `embedInNavigationView: true` if you want to be able to push screens from the presented screen._


## Routes array automatically updated

If the user taps the back button, the routes array will be automatically updated to reflect the new navigation state. Navigating back with an edge swipe gesture or via a long-press gesture on the back button will also update the routes array automatically, as will swiping to dismiss a sheet.


## Cancellation of in-flight effects on dismiss

By default, any in-flight effects initiated by a particular screen are cancelled automatically when that screen is popped or dismissed. This would normally require a lot of boilerplate, but can be entirely handled by this library without additional work. To opt out of automatic cancellation, pass `cancellationId: nil` to `forEachRoute`.


## Making complex navigation updates

SwiftUI does not allow more than one screen to be pushed, presented or dismissed within a single update. This makes it tricky to make large updates to the navigation state, e.g. when deeplinking straight to a view several layers deep in the navigation hierarchy, when going back multiple presentation layers to the root, or when restoring arbitrary navigation state. This library provides a workaround: it can break down large unsupported updates into a series of smaller updates that SwiftUI does support, interspersed with the necessary delays, and make that available as an Effect to be returned from a coordinator reducer. You just need to wrap route mutations in a call to `Effect.routeWithDelaysIfUnsupported`, e.g.:

```swift
return Effect.routeWithDelaysIfUnsupported(state.routes) {
  $0.goBackToRoot()
}
```

```swift
return Effect.routeWithDelaysIfUnsupported(state.routes) {
  $0.push(...)
  $0.push(...)
  $0.presentSheet(...)
}
```


## Composing child coordinators

The coordinator is just like any other UI unit in the Composable Architecture - comprising a `View` and a `Reducer` with `State` and `Action` types. This means they can be composed in all the normal ways SwiftUI and TCA allow. You can present a coordinator, add it to a `TabView`, even push or present a child coordinator from a parent coordinator by adding it to the routes array. When doing so, it is best that the child coordinator is only ever the last element of the parent's routes array, as it will take over responsibility for pushing and presenting new screens until dismissed. Otherwise, the parent might attempt to push screen(s) when the child is already pushing screen(s), causing a conflict.


## Identifying screens

In the example given, the coordinator's state conformed to `IndexedRouterState` and action to `IndexedRouterAction`. That means that screens were identified by their index in the routes array. This is safe because the index is stable for standard navigation updates - e.g. pushing and popping do not affect the indexes of existing screens. However, if you prefer to use `Identifiable` screens, you can manage the screens as an `IdentifiedArray` instead. You can then conform the state to `IdentifiedRouterState` and action to `IdentifiedRouterAction`, and benefit from the same terse API as the example above. There are also explicit versions of the APIs available, if you prefer not to conform to any protocols, e.g. if you wish to name properties and cases differently.


## Flexible and reusable

If the flow of screens needs to change, the change can be made easily in one place. The screen views and reducers (along with their state and action types) no longer need to have any knowledge of any other screens in the navigation flow - they can simply send an action and leave the coordinator to decide whether a new view should be pushed or presented - which makes it easy to re-use them in different contexts, and helps separate screen responsibilities from navigation responsibilities.


## How does it work?

This library uses [FlowStacks](https://github.com/johnpatrickmorgan/FlowStacks) for hoisting navigation state out of individual screens. This [blog post](https://johnpatrickmorgan.github.io/2021/07/03/NStack/) explains how that is achieved. FlowStacks can also be used in SwiftUI projects that do not use the Composable Architecture.   
