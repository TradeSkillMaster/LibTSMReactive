ReactiveStream
==============

The ``ReactiveStream`` object provides a mechanism for subscribing to a stream of values. This can
be useful when the values are more temporal as opposed to state properties. Most usefully, the same
value can be sent consecutively without the deduplication which :doc:`ReactiveState </API/state>`
provides.

Example
-------

Below is a simple example which shows how a stream can be used to handle character events. ::

   local eventStream = Reactive.GetStream(function() return nil end)

   eventStream:Publisher()
      :IgnoreIfNotEquals("JUMPED")
      :CallFunction(function() print("Jumped!") end)
      :Stored()
   eventStream:Publisher()
      :IgnoreIfNotEquals("ATTACKED")
      :CallFunction(function() print("Attacked!") end)
      :Stored()

   eventStream:Send("JUMPED") -- "Jumped!"
   eventStream:Send("JUMPED") -- "Jumped!"
   eventStream:Send("ATTACKED") -- "Attacked!"

Memory Management
-----------------

The lifecycle of stream objects is owned by LibTSMReactive, but they may be long-living. They are
acquired via the ``Reactive.GetStream()`` function and the application may call the ``:Release()``
method in order to release them back to LibTSMReactive for recycling.

API
---

.. lua:autoobject:: ReactiveStream
   :members:
