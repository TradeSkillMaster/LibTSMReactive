ReactivePublisherSchema
=======================

The ``ReactivePublisherSchema`` class is used to define the data pipeline which handles observed
values from :doc:`ReactiveState </API/state>` or :doc:`ReactiveStream </API/stream>` objects.
One thing worth noting is that these data pipelines get compiled into lua functions, so their
execution is highly performant.

Stages
------

It's important to understand the two stages of a publisher's data pipeline.

The first stage involves applying transformations and filters to the published values. The former
is accomplished via methods such as ``:Map()`` and simply transform the published values from one
value to another, passing the result to the next step of the data pipeline. Filtering is
accomplished via the ``:Ignore*()`` methods which either allow the current value through to the
next step of the data pipeline or prevent any further execution of the data pipeline. There may be
any number of transformations and filters defined in any order on the publisher schema object.

The second stage is handling the result of the data pipeline and performing some action with it.
This is accomplished with the ``:Call*()`` and ``:AssignToTableKey()`` methods. There must be
exactly one of these methods called on the publisher schema and defines the end of the data
pipeline. These methods commit the schema and return a :doc:`ReactivePublisher </API/publisher>`
object.

Share
-----

There are often situations where the first few steps of a data pipeline are common between
different data pipelines and it's advantageous to reuse the intermediate value rather than needing
to duplicate all the logic (and CPU cycles to execute the pipeline). The ``:Share()`` method is
used to designate that the value at that point in the data pipeline should be saved and shared
across multiple subsequent data pipelines. This method returns a ``ReactivePublisherSchemaShared``
object which has most of the same methods, but allows continuing the data pipeline from the steps
that would otherwise commit it (i.e. ``:CallMethod()``) at which point the previuosly-saved
intermediate value is sent to any following data pipeline steps. The data pipeline is finally
committed via the ``:EndShare()`` method. See the example below for what this looks like in
practice.

Flat Map
--------

In more advanced cases, it's desirable to be able to transform published values into a new
publisher. The ``:FlatMapCall*()`` methods are used for this, where the first argument specifies
a function which gets published values and returns a new publisher, with the values from that new
publisher then being handled by the specified function / method.

Example
-------

Here's an example which creates a publisher from an expression and shares its value to show / hide
add and subtract buttons within a numeric input when the input is focused or hovered. ::

   self._state:Publisher([[subAddEnabled and (mouseOver or hasFocus)]])
      :Share()
      :CallMethod(self._subIcon, "SetShown")
      :CallMethod(self._subBtn, "SetShown")
      :CallMethod(self._addIcon, "SetShown")
      :CallMethod(self._addBtn, "SetShown")
      :EndShare()

Here's another example for an input field which can optionally have a border color as well as
showing the border as red when the input's value is invalid. ::

   self._state:Publisher([[borderColor or not isValid]])
      :Share()
      :CallMethod(self._borderTexture, "SetShown")
      :ReplaceBooleanWith(BORDER_THICKNESS, 0)
      :CallMethod(self._backgroundTexture, "SetInset")
      :EndShare()
   self._state:CallMethod([[isValid and borderColor or "FEEDBACK_RED"]])
      :CallMethod(self._borderTexture, "SetColor")

Memory Management
-----------------

The lifecycle of publisher schema objects is owned entirely by LibTSMReactive. They are acquired
exclusively via methods on :doc:`ReactiveState </API/state>` and
:doc:`ReactiveStream </API/stream>` objects and are recycled internally when they are committed.

API
---

.. lua:autoobject:: ReactivePublisherSchemaBase
   :members:
   :exclude-members: Get

.. lua:autoobject:: ReactivePublisherSchema
   :members:
   :exclude-members: Get

.. lua:autoobject:: ReactivePublisherSchemaShared
   :members:
   :exclude-members: Get
