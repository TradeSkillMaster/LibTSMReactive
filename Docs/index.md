# LibTSMReactive

[LibTSMReactive](https://github.com/TradeSkillMaster/LibTSMReactive) is a reactive framework
based around observable state objects. One of the primary goals of the Reactive framework is to
make it easy to build state-driven UI, where the UI can respond to specific state fields being
updated without needing to completely rerender the entire UI. For example, if we have a UI that
displays the player's current amount of gold among other player statistics, we only need to update
the player gold text content when that value changes, rather than redrawing the entire window.

## Dependencies

This library has the following external dependencies which must be installed separately within the
target application:

* [LibTSMClass](https://github.com/TradeSkillMaster/LibTSMClass)
* [LibTSMCore](https://github.com/TradeSkillMaster/LibTSMCore)
* [LibTSMUtil](https://github.com/TradeSkillMaster/LibTSMUtil)

## Installation

If you're using the [BigWigs packager](https://github.com/BigWigsMods/packager), you can reference
LibTSMReactive as an external library:

```yaml
externals:
  Libs/LibTSMReactive:
    url: https://github.com/TradeSkillMaster/LibTSMReactive.git
```

Otherwise, you can download the
[latest release directly from GitHub](https://github.com/TradeSkillMaster/LibTSMReactive/releases).

## Overview by Example

Below is an overview of all the major components of the Reactive framework. They are all presented
via an example of a button which updates its text to be a count of the number of times it has been
clicked.

We'll start by initializing our LibTSMCore module, pulling in the LibTSMReactive modules and
classes we'll need, and creating a local `private` table to store any file-scoped variables and
functions.

```lua
-- ClickCounter.lua
local MyUIModule = select(2, ...).MyUIModule
local ClickCounter = MyUIModule:Init("ClickCounter")
local Reactive = MyUIModule:From("LibTSMReactive"):Include("Reactive")
local UIManager = MyUIModule:From("LibTSMReactive"):Include("UIManager")
local private = {}
```

### State

The state object is a strongly-typed representation of all the state which is driving a given
component. The schema of the state is first defined via a [ReactiveStateSchema](./ReactiveStateSchema)
object.

For our example, we just need a single state field to track the number of times the button has
been clicked. This generally gets defined at the top of the module and is local to the file.

```lua
local STATE_SCHEMA = Reactive.CreateStateSchema("ClickCounterUIState")
   :AddNumberField("numClicks", 0)
   :Commit()
```

Now that we have the state schema, we can create a state object from it. The state object is
strongly-typed with the fields and default values defined by the schema.

```lua
ClickCounter:OnModuleLoad(function()
   local state = STATE_SCHEMA:CreateState()
   print(state.numClicks) -- 0

   -- ...
end)
```

### UI Manager

The [UIManager](./UIManager) class provides a framework for managing the state which drives a
given UI and responding to actions which mutate the state. As a general convention, the state
object should not be stored by the module, but rather owned by the UIManager object and only
accessed via methods and callbacks on the UIManager object.

```lua
private.manager = UIManager.Create("CLICK_COUNTER", state, private.ActionHandler)
   :AddFrameBuilder(private.CreateFrame)
```

The action handler is responsible for responding to actions in order to mutate the state.

```lua
---@param manager UIManager
---@param state ClickCounterUIState
function private.ActionHandler(manager, state, action, ...)
   if action == "ACTION_HANDLE_CLICK" then
      state.numClicks = state.numClicks + 1
   else
      error("Unknown action: "..tostring(action))
   end
end
```

The frame builder creates the actual UI.

```lua
---@param state ClickCounterUIState
function private.CreateFrame(state)
   local button = CreateFrame("Button", nil, UIParent, "UIPanelButtonTemplate")
   button:SetPoint("CENTER")
   button:SetWidth(120)
   button:SetHeight(30)
   button:SetText(format("%d clicks", state.numClicks))
   button:SetScript("OnClick", private.manager:CallbackToProcessAction("ACTION_HANDLE_CLICK"))
   -- To be continued...
end
```

### Publishers

Publishers are used to subscribe to state changes and define the logic that should be run in
reaction to state changes. They can be used to define fairly complex data pipelines and are the
crux of what makes the Reactive framework so powerful.

For our example, we want to set the text of the button based on the `numClicks` state property,
mapped to a formatted string. This can be accomplished with the following publisher definition,
added to the end of `private.CreateFrame(state)`.

```lua
private.manager:AddCancellable(state:Publisher("numClicks")
   :ToStringFormat("%d clicks")
   :CallMethod(button, "SetText")
)
```

What's happening here:

1. `state:Publisher("numClicks")` creates a publisher that fires whenever `numClicks` changes.
2. `:ToStringFormat("%d clicks")` transforms the number into a formatted string.
3. `:CallMethod(button, "SetText")` consumes the value by calling `button:SetText()` — this also
   commits the publisher and returns a `ReactivePublisher` object.
4. `:AddCancellable()` assigns the publisher's lifecycle to the UIManager, which also immediately
   processes the initial value so the button text is set on creation.

For the full set of methods available for defining publisher steps, see
[ReactivePublisherSchema](./ReactivePublisherSchema). For ways to create publishers from state, see
[ReactiveState](./ReactiveState).
