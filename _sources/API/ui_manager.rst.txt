UIManager
=========

The ``UIManager`` class provides the framework for driving state updates in response to UI
interactions or other events. It also manages many of the other components of building a
state-driven UI, from creating the frame itself, to managing the state and related publishers.

Memory Management
-----------------

The ``UIManager`` objects are intended to never be GC'd and have a static lifecycle (i.e. one
that's equal to the lifecycle of the application), but there is nothing preventing them from being
GC'd.

API
---

.. lua:autoobject:: UIManager
   :members:
