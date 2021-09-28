# TCACoordinators

_The coordinator pattern in the Composable Architecture_

`TCACoordinators` brings a flexible approach to navigation in SwiftUI using the [Composable Architecture (TCA)](https://github.com/pointfreeco/swift-composable-architecture). It allows you to manage complex navigation and presentation flows with a single piece of state, hoisted into a high-level coordinator view. Using this pattern, you can write isolated screen views that have zero knowledge of their context within the navigation flow of an app. It achieves this by combining existing tools in TCA such as `Reducer.forEach`, `Reducer.pullback` and `SwitchStore` with [a novel approach to handling navigation in SwiftUI](https://github.com/johnpatrickmorgan/FlowStacks). 

## Usage Example

### Step 1 - Create a screen reducer

First, identify all possible screens that are part of the particular navigation flow you're modelling. The goal will be to combine their reducers into a single reducer - one that can drive the behaviour of any of those screens. Both the state and action types will be the sum of the individual screens' state and action types:

```swift
enum ScreenState: Equatable {
  case numbersList(NumbersListState)
  case numberDetail(NumberDetailState)
}

enum ScreenAction {
  case numbersList(NumbersListAction)
  case numberDetail(NumberDetailAction)
}
```

And the screen reducer will combine each individual screens' reducers into one:

```swift
let screenReducer = Reducer<ScreenState, ScreenAction, Void>.combine(
  numbersListReducer
    .pullback(
      state: /ScreenState.numbersList,
      action: /ScreenAction.numbersList,
      environment: { _ in }
    ),
  numberDetailReducer
    .pullback(
      state: /ScreenState.numberDetail,
      action: /ScreenAction.numberDetail,
      environment: { _ in }
    )
)
```

### Step 2 - Create a coordinator reducer

The coordinator will manage multiple screens in a navigation flow. Its state should include an array of `ScreenState`s, representing the navigation stack: i.e. appending a new screen state to this array will cause the corresponding screen to be pushed.

```swift
struct CoordinatorState: Equatable, IndexedScreenCoordinatorState {
  var screens: [ScreenState]
}
```

The coordinator's action should include two special cases. The first allows screen actions to be dispatched to the correct screen in the stack. The second allows the screens array to be updated automatically when a user taps back:

```swift
enum CoordinatorAction: IndexedScreenCoordinatorAction {
  case screenAction(Int, ScreenAction)
  case updateScreens([ScreenState])
}
```

The coordinator's reducer uses `forEachIndexedScreen` to apply the `screenReducer` to each screen in the `screens` array, and combines that with a second reducer that defines when new screens should be pushed or popped:

```swift
let coordinatorReducer: Reducer<CoordinatorState, CoordinatorAction, Void> = screenReducer
  .forEachIndexedScreen(environment: { _ in })
  .updateScreensOnInteraction()
  .combined(
    with: Reducer { state, action, environment in
      switch action {
      case .screenAction(_, .numbersList(.numberSelected(let number))):
        state.push(.numberDetail(.init(number: number)))

      case .screenAction(_, .numberDetail(.goBackTapped)):
        state.pop()

      case .screenAction(_, .numberDetail(.showDouble(let number))):
        state.push(.numberDetail(.init(number: number * 2)))

      default:
        break
      }
      return .none
    }
  )
  .cancelEffectsOnDismiss()
```

Note the call to `cancelEffectsOnDismiss()` at the end. It's often desirable to cancel any in-flight effects initiated by a particular screen when that screen is popped or dismissed. This would normally require a fair amount of boilerplate, but can now be achieved by simply chaining a call to `cancelEffectsOnDismiss()` on the reducer. 

The call to `updateScreensOnInteraction()` ensures the screens array is updated whenever the user swipes back or taps the back button.

### Step 3 - Create a coordinator view

With that in place, a `CoordinatorView` can be created. It will use a `NavigationStore`, which translates the array of screens into a nested list of views with invisible `NavigationLinks`. The `NavigationStore` takes a closure that can create the view for any screen in the navigation flow. A `SwitchStore` is the natural way to achieve that, with a `CaseLet` for each of the possible screens:

```swift
struct CoordinatorView: View {
  let store: Store<CoordinatorState, CoordinatorAction>

  var body: some View {
    NavigationStore(store: store) { scopedStore in
      SwitchStore(scopedStore) {
        CaseLet(
          state: /ScreenState.numbersList,
          action: ScreenAction.numbersList,
          then: NumbersListView.init
        )
        CaseLet(
          state: /ScreenState.numberDetail,
          action: ScreenAction.numberDetail,
          then: NumberDetailView.init
        )
      }
    }
  }
}
```

## Advantages

This allows navigation to be managed with a single piece of state. As well as mutating the array directly, there are some useful protocol extensions to allow common interactions such as `state.push(newScreen)`, `state.pop()`, `state.popToRoot()`, or even `state.popTo(/ScreenState.numbersList)`. If the user taps or swipes back, or uses the long press gesture to go further back, the navigation state will automatically get updated to reflect the change.

This approach is flexible: if the flow of screens needs to change, the change can be made easily in one place. The screen views themselves no longer need to have any knowledge of any other screens in the navigation flow - they can simply send an action and leave the coordinator to decide whether a new view should be pushed or presented - which makes it easy to re-use them in different contexts.

## Child Coordinators

The coordinator is just like any other UI unit in the Composable Architecture - comprising a `View` and a `Reducer` with `State` and `Action` types. This means they can be composed in all the normal ways SwiftUI and TCA allow. You can present a coordinator, add it to a TabView, even push a child coordinator onto the navigation stack of a parent coordinator. Note that `NavigationStore` does not wrap its content in a `NavigationView` - that way, multiple coordinators, each with its own `NavigationStore`, can be nested within a single `NavigationView`.

## Presentation

The example given was a navigation flow, but it can be changed to a presentation flow by just changing the `NavigationStore` to a `PresentationStore`. Each new screen would then be presented rather than pushed.

## Identifying Screens

In the example given, the coordinator's state conformed to `IndexedScreenCoordinatorState` and action to `IndexedScreenCoordinatorAction`. That means that screens were identified by their index in the screens array. This is safe because the index is stable for standard navigation updates - e.g. pushing and popping do not affect the indexes of existing screens. However, if you prefer to use `Identifiable` screens, you can manage the screens as an `IdentifiedArray` instead. You can then conform the state to `IdentifiedScreenCoordinatorState` and action to `IdentifiedScreenCoordinatorAction`, to gain the same terse API as the example above. There are also explicit versions of the APIs available, if you prefer not to conform to any protocols, e.g. if you wish to name properties and cases differently.

## How does it work?

This library uses [FlowStacks](https://github.com/johnpatrickmorgan/FlowStacks) for hoisting navigation state out of individual screens. This [blog post](https://johnpatrickmorgan.github.io/2021/07/03/NStack/) explains how that is achieved. FlowStacks can also be used in SwiftUI projects that do not use the Composable Architecture.   

## Limitations

SwiftUI does not currently support all possible mutations of the screens array. It does not allow more than one screen to be pushed, presented or dismissed in a single update. It's possible to pop any number of screens in one update for navigation flows but not for presentation flows. Hopefully, these limitations are temporary.
