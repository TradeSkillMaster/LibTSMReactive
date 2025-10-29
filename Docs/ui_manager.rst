UIManager
=========

The ``UIManager`` class is intended to be used with the ``Reactive`` framework and provides a
framework for building state-driven UIs. See the :doc:`Reactive Framework </reactive>` documentation for more
information about how to use the ``UIManager`` class.

Memory Management
-----------------

The ``UIManager`` objects are intended to never be GC'd and have a static lifecycle (i.e. one
that's equal to the lifecycle of the application), but there is nothing preventing them from being
GC'd.

API
---

.. lua:autoobject:: UIManager
   :members:
