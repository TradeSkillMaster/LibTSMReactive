UIBindings
==========

The ``UIBindings`` class is intended to be used with the ``Reactive`` framework and aims to provide
an easy-to-use mechanism to bind specific values to fields of a ``ReactiveState`` object.

Example
-------

The following demonstrates a simple usage of the UIBindings class. ::

   -- PlayerHealthMonitor.lua
   local MyModule = select(2, ...).MyModule
   local PlayerHealthMonitor = MyModule:Init("PlayerHealthMonitor")
   local UIBindings = MyModule:From("LibTSMReactive"):IncludeClassType("UIBindings")

   local bindings = UIBindings.Create()

   function PlayerHealthMonitor.BindHealthValue(state, key)
      bindings:Add("HEALTH_VAUE", state, key)
   end

   local function OnHealthUpdateEvent(health)
      bindings:Process("HEALTH_VALUE", health)
   end

   -- MyUIFile.lua
   -- ...
   local state = ... -- The local `ReactiveState` object with a "health" key

   -- Update our local state's health value based on values from the PlayerHealthMonitor module.
   PlayerHealthMonitor.BindHealthValue(state, "health")

Memory Management
-----------------

The ``UIBindings`` objects are intended to never be GC'd and have a static lifecycle (i.e. one
that's equal to the lifecycle of the application), but there is nothing preventing them from being
GC'd.

API
---

.. lua:autoobject:: UIBindings
   :members:
