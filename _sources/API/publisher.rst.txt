ReactivePublisher
=================

The ``ReactivePublisher`` class is used to represent a committed
:doc:`ReactivePublisherSchema </API/publisher_schema>` object. It primarily facilitates lifecycle
management of the data pipeline defined by the schema.

Stored
------

When a schema object is committed, a publisher object is created in an initialized state. The data
pipeline will not be active until the publisher is stored by calling the ``:StoreIn()`` or
``:Stored()`` method. This is used to assign ownership of the publisher and starts the data
pipeline. This also triggers the processing of the initial value of the publisher (i.e. the current
value of the :doc:`ReactiveState </API/state>` object or the initial value specified when creating
the :doc:`ReactiveStream </API/publisher>`). The publisher can then be cancelled (automatically
releasing it back into the internal LibTSMReactive pool) by calling the ``:Cancel()`` method.

Disabled
--------

The publisher can be disabled in order to temporarily stop the data pipeline. This is done by
calling the ``:Disable()`` method. It can then be enabled again by calling the
``:EnableAndReset()`` method. The behavior is identical to the publisher being cancelled and
recreated, meaning that the initial value will once again be processed by the data pipeline, and
any ``:IgnoreDuplicate()`` calls will act as if there were no previous values published.

Memory Management
-----------------

The lifecycle of publisher objects is owned by LibTSMReactive, but they may be long-living. They
are acquired by committing a publisher schema and the application may call the ``:Cancel()`` method
in order to release them back to LibTSMReactive for recycling.

API
---

.. lua:autoobject:: ReactivePublisher
   :members:
   :exclude-members: Get
