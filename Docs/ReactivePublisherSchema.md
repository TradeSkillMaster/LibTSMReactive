# ReactivePublisherSchema

The `ReactivePublisherSchema` class is used to define the data pipeline which handles observed
values from [ReactiveState](./ReactiveState) or [ReactiveStream](./ReactiveStream) objects. These
data pipelines are compiled into Lua functions, so their execution is highly performant.

## Stages

The data pipeline has two stages:

The **first stage** applies transformations and filters to published values. Transformations (e.g.
`:Map()`) change the value passing to the next step. Filters (e.g. `:Ignore*()`) either allow
the current value through or halt the pipeline. Any number of transformations and filters may be
defined in any order.

The **second stage** handles the final value via `:Call*()` or `:AssignToTableKey()`. Exactly one
of these must be called — it commits the schema and returns a [ReactivePublisher](./ReactivePublisher)
object.

## Share

The `:Share()` method designates that the value at that point in the pipeline should be saved and
shared across multiple subsequent data pipelines. It returns a `ReactivePublisherSchemaShared`
object, which allows continuing from the commit methods before being finalized via `:EndShare()`.

```lua
self._state:Publisher([[subAddEnabled and (mouseOver or hasFocus)]])
   :Share()
   :CallMethod(self._subIcon, "SetShown")
   :CallMethod(self._subBtn, "SetShown")
   :CallMethod(self._addIcon, "SetShown")
   :CallMethod(self._addBtn, "SetShown")
   :EndShare()
```

## Flat Map

The `:FlatMapCall*()` methods allow transforming published values into a new publisher, where the
first argument is a function that receives published values and returns a new publisher.

## Memory Management

Publisher schema objects are acquired exclusively via methods on [ReactiveState](./ReactiveState)
and [ReactiveStream](./ReactiveStream) and are recycled internally when committed.

## API

<!--@include: ./api/ReactivePublisherSchemaBase.md-->

<!--@include: ./api/ReactivePublisherSchema.md-->

<!--@include: ./api/ReactivePublisherSchemaShared.md-->
