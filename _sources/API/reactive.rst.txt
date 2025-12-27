Reactive
========

The Reactive module provides functions for creating :doc:`ReactiveStateSchema </API/state_schema>`
and :doc:`ReactiveStream </API/stream>` objects.

It also provides an API for creating one-shot publishers, which simply publish a single value. This
can be useful in more niche situations where there exists an API which can accept a publisher, but
only a single value is needed by the consumer of the API.

.. lua:autoobject:: Reactive
   :members:
