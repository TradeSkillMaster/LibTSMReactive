LibTSMReactive
==============

The Reactive framework is based around observable state objects. One of the primary goals of
the Reactive framework is make it easy to build state-driven UI, where the UI can respond to
specific state fields being updated without needing to completely rerender the entire UI. For
example, if we have a UI that displays the player's current amount of gold among other player
statistics, we only need to update the player gold text content when that value changes,
rather than redrawing the entire window.

Dependencies
------------

This library has the following external dependencies which must be installed separately within the
target application:

* `LibTSMClass`_
* `LibTSMCore`_
* `LibTSMUtil`_

.. _LibTSMClass: https://github.com/TradeSkillMaster/LibTSMClass
.. _LibTSMCore: https://github.com/TradeSkillMaster/LibTSMCore
.. _LibTSMUtil: https://github.com/TradeSkillMaster/LibTSMUtil

Installation
------------

If you're using the `BigWigs packager`_, you can reference LibTSMReactive as an external library.

.. code-block:: yaml

   externals:
      Libs/LibTSMReactive:
         url: https://github.com/TradeSkillMaster/LibTSMReactive.git

Otherwise, you can download the `latest release directly from GitHub`_.

.. _BigWigs packager: https://github.com/BigWigsMods/packager
.. _latest release directly from GitHub: https://github.com/TradeSkillMaster/LibTSMReactive/releases

Overview by Example
-------------------

Below is an overview of all the major components of the Reactive framework provided by
LibTSMReactive. They are all presented via an example of a button which updates its text to be a
count of the number of times it has been clicked.

We'll start by initializing our `LibTSMCore`_ module, pulling in the LibTSMReactive modules and
classes we'll need, and creating a local ``private`` table to store any file-scoped variables and
functions. ::

   -- ClickCounter.lua
   local MyUIModule = select(2, ...).MyUIModule
   local ClickCounter = MyUIModule:Init("ClickCounter")
   local Reactive = MyUIModule:From("LibTSMReactive"):Include("Reactive")
   local UIManager = MyUIModule:From("LibTSMReactive"):Include("UIManager")
   local private = {}

.. _LibTSMCore: https://github.com/TradeSkillMaster/LibTSMCore

State
^^^^^

The state object is a strongly-typed representation of all the state which is driving a given
component. The schema of the state is first defined via a
:doc:`ReactiveStateSchema </API/state_schema>` object.

For the purposes of our example, we just need a single state field to track the number of times the
button has been clicked. This generally gets defined at the top of the module and is local to the
file. ::

   local STATE_SCHEMA = Reactive.CreateStateSchema("CLICK_COUNTER_UI_STATE")
      :AddNumberField("numClicks", 0)
      :Commit()

Now that we have the state schema, we can create a state object from it. This state object is
strongly-typed with the fields and default values defined by the schema. The state object typically
is created on module load. ::

   ClickCounter:OnModuleLoad(function()
      local state = STATE_SCHEMA:CreateState()
      print(state.numClicks) -- 0

      -- ...
   end)

UI Manager
^^^^^^^^^^

The :doc:`UIManager </API/ui_manager>` class provides a framework for managing the state which
drives a given UI and respond to actions which mutate the state. As a general convention, the state
object should not be stored by the module, but rather owned by the UIManager object and only
accessed via methods and callbacks on the UIManager object.

Going back to our example, the following code will get added to our module load function. ::

   private.manager = UIManager.Create("CLICK_COUNTER", state, private.ActionHandler)
      :AddFrameBuilder(private.CreateFrame)

Note that this references two functions we haven't defined yet. The first is the action handler
which is responsible for responding to actions in order to mutate the state. In this case, we have
a single action we want to respond to, which is the button being clicked. ::

   ---@param manager UIManager
   ---@param state ClickCounterUIState
   function private.ActionHandler(manager, state, action, ...)
      if action == "ACTION_HANDLE_CLICK" then
         state.numClicks = state.numClicks + 1
      else
         error("Unknown action: "..tostring(action))
      end
   end

The other function we need to define is the one which actually creates our UI frame. For the
purpose of this example, we'll simply create a button in the middle of the screen and trigger the
action when it's clicked. ::

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

Publishers
^^^^^^^^^^

Publishers are used to subscribe to state changes and define the logic that should be run in
reaction to state changes. They can be used to define fairly complex data pipelines and are the
crux of what makes the Reactive framework so powerful.

For the purposes of our example, we want to set the text of the button based on the ``numClicks``
state property. We also want to map it to a formatted string to make it more useful to the user.
This can be accomplished with the following publisher definition, added to the end of the
``private.CreateFrame(state)`` function. ::

   private.manager:AddCancellable(state:Publisher("numClicks")
      :ToStringFormat("%d clicks")
      :CallMethod(button, "SetText")
   )

There are a few things going on here which are worth walking through:

1. We're creating a publisher which will handle changes to the ``numClicks`` state property.
2. The following steps of the publisher will receive the new ``numClicks`` values. In this case,
   the next step is mapping the published values with a format string of "%d clicks". This
   transforms the data value being handled, such that following steps now receive a
   "### clicks" string (with the actual value inserted for '###').
3. Lastly, the publisher chain is consuming the published value by calling the ``:SetText()``
   method on our button with the published values.
4. The result of calling a publisher method which consumes the value (i.e. ``CallMethod()``) is
   that the publisher is committed. Under the hood, whats happening is that all the previous steps
   were operating on a ``ReactivePublisherSchema`` object, and once that's committed, a
   ``ReactivePublisher`` object is returned.
5. This ``ReactivePublisher`` object is referred to by the Reactive framework as a "cancellable"
   because it can be used to cancel the publisher change for lifecycle purposes. We're passing this
   cancellable to our UIManager as a way of assigning the lifecycle of the publisher to the
   UIManager. Internally, the UIManager is calling the ``:Stored()`` method of the publisher, which
   is what finally triggers the publisher to start subscribing to state updates and handling
   values. In this case, it will also immediately process the initial value of the ``numClicks``
   property, which is handy so that we don't need to explicitly set the initial text value of our
   button.

For the full set of methods available for defining publisher steps, see the
:doc:`ReactivePublisherSchema </API/publisher_schema>` API documentation. Similarly, there are many
ways to create a publisher from a state object, which are covered in the
:doc:`ReactiveState </API/state>` documentation.

License and Contributions
-------------------------

LibTSMReactive is licensed under the MIT license. See LICENSE.txt for more information. If you
would like to contribute to LibTSMReactive, opening an issue or submitting a pull request against
the `LibTSMReactive GitHub project`_ is highly encouraged.

.. _LibTSMReactive GitHub project: https://github.com/TradeSkillMaster/LibTSMReactive

.. toctree::
   :hidden:

   Home <self>
   API/index
