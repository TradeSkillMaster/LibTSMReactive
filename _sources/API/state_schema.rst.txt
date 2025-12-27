ReactiveStateSchema
===================

As the name suggests, the ``ReactiveStateSchema`` class is used to define the schema of a state
object. The state object is strongly-typed, so the schema is responsible for defining all the
fields, their types, and their default values. The type of the field is defined by the API method
which is used to add it. See the ``:Add*Field()`` method documentation below. Any value assigned to
a state property will be checked against the schema at assignment time and result in an error if
it's of the wrong type. All state changes are tracked based on simple equality checks between
values.

Field Data Types
----------------

State objects support a variety of different types of properties as described below.

Simple Data Types
^^^^^^^^^^^^^^^^^

Each of the simple data types (string, number, boolean) can be added either as a required (non-nil)
field with a default value, or as an optional (nillable) field where the default is nil.

Enums
^^^^^

`LibTSMUtil`_ provides an enum type which can also be added as state fields (either optional or
not). The user-defined enum type is provided when adding an enum field. This allows the field to be
constrained to a specific enum type, as opposed to allowing values of any enum type.

.. _LibTSMUtil: https://github.com/TradeSkillMaster/LibTSMUtil

Optional Table
^^^^^^^^^^^^^^

Optional table fields can be added to store more complex context which isn't as strictly
type-checked on the state object. Note that since changes are checked when assigning to the state
property, changing a field within a table property does not result in that change propagating to
publishers which are observing the state. Similarly, assigning the same table to a table property
does not result in a change being observed. In practice, optional table fields are used to store
context that is associated with the state, but is not necessarily being observed for changes.

Optional Class
^^^^^^^^^^^^^^

Optional class fields behave very similarly to optional table fields. The main reason they are
provided over just treating class objects as tables (which they are) is for type checking and
enhanced language server support.

Extending
---------

There are situations where state schemas are associated with classes, especially for UI components
where it's common for there to also be subclasses. In these cases, the state schema provides a
simple mechanism for the subclasses to extend the schema of their parent class to avoid needing to
redefine the same fields and potentially introduce bugs if the child state schema doesn't satisfy
the requirements of the parent class.

This is accomplished with the ``:Extend()`` method which creates a new state schema object that
inherits all the fields of the original schema. New fields can then be added as normal, but also
the default values of existing fields can be changed via the ``:UpdateFieldDefault()`` method.

Example
-------

Below is an exmaple of defining a simple state schema for text and button UI components. ::

   local TEXT_STATE_SCHEMA = Reactive.CreateStateSchema("TEXT_STATE")
      :AddStringField("justifyH", "LEFT")
      :AddStringField("text", "")
      :Commit()

   local BUTTON_STATE_SCHEMA = TEXT_STATE_SCHEMA:Extend("BUTTON_STATE")
      :UpdateFieldDefault("justifyH", "CENTER")
      :AddBooleanField("enabled", true)
      :Commit()

Memory Management
-----------------

The ``ReactiveStateSchema`` objects are intended to never be GC'd and have a static lifecycle (i.e.
one that's equal to the lifecycle of the application), but there is nothing preventing them from
being GC'd (assuming there are no state objects with a reference to them).

API
---

.. lua:autoobject:: ReactiveStateSchema
   :members:
