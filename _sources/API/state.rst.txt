ReactiveState
=============

The ``ReactiveState`` object is at the core of the Reactive framework. It is a strongly typed
object which allows for observing changes via publishers. It is created from
:doc:`ReactiveStateSchema </API/state_schema>` objects. In addition to providing the properties
defined by the schema, it also provides various methods for creating publishers which handle
changes to said properties.

Creating Publishers
-------------------

:doc:`ReactivePublisherSchema </API/publisher_schema>` objects are created from state objects in
order to define data pipelines which get triggered when the value of one or more of the state
properties changes. There are a few different ways provided to create these publishers from a state
object in order to optimize for common usage patterns in an optimized way.

Single Key
^^^^^^^^^^

The simplest way is to simply observe a single state field via the ``:Publisher()`` method. In this
case, just the value of the specified field will be provided to the publisher's data pipeline.

Expression
^^^^^^^^^^

In practice, it's common to want to observe either multiple keys or even to observe the result of
a simple expression applied to the state. For example, enabling the "Submit" button on a form only
if both its fields have been filled. The ``:Publisher()`` method allows passing in a simple lua
expression which can access the properties of the state object. The result of this expression is
then passed to the publisher's data pipeline (when it changes). Under the hood, this expression
then gets included in the publisher's compiled data pipeline, making this an extremely optimized
way of defining complex state observation logic. See the example code below for some examples of
how this can be used, but there are a few constraints on the expression:

1. All state properties are exposed as globals. If you have a state with ``num`` and ``str``
   fields, they are accessed within the expression by their names directly.
2. No global variables, functions, or standard library methods are allowed to be used within the
   expression, including string/table methods (i.e. ``str:sub(1, 1)`` is not allowed). The only
   exception is that the ``min()`` and ``max()`` functions are made available.
3. Tables cannot be created within the expression (no ``{`` or ``}`` tokens allowed). However,
   string literals are allowed (with double quotes, i.e. ``"Hello World"``).
4. An ``EnumEquals()`` method is provided to allow for checking for specific enum field values.

Function
^^^^^^^^

For cases where more complex logic is required than what is possible within an expression, a
function can be provided which operates on a subset of the state properties and produces a single
value that is then passed to the publisher's data pipeline (when it changes). This can be used to
get around some of the constraints imposed when using expressions, or just to call additional
functions as required to determine the result. It's important to note that this function **must**
only depend on the state values being passed in to it, can not depend on any extrenal state or
have any side-effects, and must be deterministic (meaning the output must always be the same for a
given set of inputs).

Multiple Keys
^^^^^^^^^^^^^
A ``:PublisherForKeys()`` method is also provided which provides the entire state object to the
publisher's data chain whenever one of the specified properties changes. Using this is generally
discouraged in favor of one of the other options listed above if at all possible. However, there
are cases where this method is especially useful. For example, if you want to trigger some function
call in response to any of the state changing, without necessarily caring about the specific state
property values.

Example
-------

Below is an example which shows off the various ways to create publishers from a state object. ::

   local cancellables = {}
   local OPERATION = EnumType.New("OPERATION", {
      TIMES = EnumType.NewValue(),
      DIVIDE = EnumType.NewValue(),
   })
   local STATE_SCHAME = Reactive.CreateStateSchema("TEST_STATE")
      :AddEnumField("operation", OPERATION, OPERATION.TIMES)
      :AddNumberField("num1", 10)
      :AddNumberField("num2", 2)
      :Commit()
   local state = STATE_SCHAME:CreateState()
      :SetAutoStore(cancellables)

   state:Publisher([[(EnumEquals(operation, TIMES) and (num1 * num2)) or (num1 / num2)]])
      :CallFunction(function(result) print(format("New result: %d", result)) end)
   -- "New result: 20"
   state:Publisher("operation")
      :CallFunction(function(operation) print(format("Operation changed: %s", tostring(operation))) end)
   -- "Operation changed: OPERATION.TIMES"

   state.num2 = 1
   -- "New result: 10"

   -- Change the operation such that the result doesn't change
   state.operation = OPERATION.DIVIDE
   -- "Operation changed: OPERATION.DIVIDE"

Memory Management
-----------------

The ``ReactiveState`` objects are intended to never be GC'd and have a static lifecycle (i.e. one
that's equal to the lifecycle of the application) and an internal reference is kept to them within
LibTSMReactive which will prevent them from being GC'd.

API
---

.. lua:autoobject:: ReactiveState
   :members:
