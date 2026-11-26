# Animating filtered Qt Quick lists

## Why replacing a JavaScript-array model looks abrupt

### Takeaway
Binding `ListView.model` to a newly computed JavaScript array (for example, `source.filter(...)`) replaces the model as a whole; it does not report row-level insertions/removals. Qt documents `populate` for the case where visible delegates are completely replaced, but `add`/`remove` transitions are for model operations, so a wholesale replacement cannot reliably animate each matching row as a granular change.

### Cited Findings
- Qt's `ListView` docs say `populate` applies when the model changes such that visible delegates are completely replaced; `add` applies to items added after creation, and explicitly does not apply when the model changes (that uses `populate`). [ListView: add](https://doc.qt.io/qt-6/qml-qtquick-listview.html#add-prop), [ListView: populate](https://doc.qt.io/qt-6/qml-qtquick-listview.html#populate-prop)
- A Qt Forum answer explains that a JS array supplies no notifications for inserted, removed, or changed entries; assigning a new JS array makes the view rebuild, whereas a notifying model allows only necessary changes. This is community guidance, consistent with Qt's model-operation-based transition API. [Qt Forum example](https://forum.qt.io/topic/76722/how-can-i-get-listview-to-create-destroy-items-less-predictive)
- Qt's `ViewTransition` docs define add/remove/move transitions around model operations and warn that transitions can interrupt one another. For example, a newly added row can be displaced before its add animation completes; transitions touching the same properties should leave those properties in a valid final state. [ViewTransition](https://doc.qt.io/qt-6/qml-qtquick-viewtransition.html)

### Inferences
- For a search filter, a JS expression that creates a fresh result array each time is a poor choice if the goal is to animate only the rows entering/leaving the result set. `populate` can animate a wholesale visible replacement, but does not identify logical row identity or create individual remove/add semantics.
- Use stable item identity and a model that emits granular changes; configure `remove`, `add`, and `displaced` (or operation-specific displaced transitions) for fade-out/fade-in and movement.

### Gaps
- Qt's public docs describe transition triggers, but do not specify the exact internal diff/reuse algorithm for JS-array replacement. Do not rely on undocumented delegate retention behavior.

## Transitions and model choices for filtered results

### Takeaway
For animated filtering, keep a persistent model and mutate it with row-level operations, or use a proxy/filtering model that exposes proper model notifications. `ListModel` provides insert/remove/move operations; a C++ `QAbstractItemModel`/proxy is appropriate for larger or more complex datasets.

### Cited Findings
- `ListModel` inherits `QAbstractListModel` and exposes `append`, `insert`, `move`, `remove`, `set`, and `setProperty`; these are operations on the existing model rather than replacement of its `model` property. [ListModel](https://doc.qt.io/qt-6/qml-qtqml-models-listmodel.html)
- `ListView` transition roles: `add` animates newly added visible items; `remove` animates removed items (the item has already left the model, so its removed-index model data is invalid); `move` animates items explicitly moved by the model; `displaced` animates other rows shifted by add/move/remove. [ListView transitions](https://doc.qt.io/qt-6/qml-qtquick-listview.html)
- `populate` runs at initial creation, on a wholesale visible replacement, or a QAbstractItemModel reset. It does not run just because scrolling instantiates delegates, and new delegates made visible by later model changes use `add`. [ListView: populate](https://doc.qt.io/qt-6/qml-qtquick-listview.html#populate-prop)
- Qt's ListView docs recommend filtering the model so hidden rows are not loaded; they identify `QSortFilterProxyModel` as one option. [ListView: hiding delegates](https://doc.qt.io/qt-6/qml-qtquick-listview.html#hiding-delegates)
- Reliable non-Qt example: Quickshell's `ScriptModel` wraps a changing JS expression, computes model operations, and specifically documents that this enables ListView animations; its example filters values and it warns that the values must be unique (duplicates make behavior undefined). This is project-specific, not a Qt-provided type. [Quickshell ScriptModel source/docs](https://github.com/quickshell-mirror/quickshell/blob/43d4fa9e/src/core/scriptmodel.hpp)

### Inferences
- In QML-only code, retain the same `ListModel` and reconcile desired filtered IDs against its rows (remove excluded rows, insert newly included rows, and move only if order changed). Avoid `clear()` followed by repopulating if the intended effect is continuous row-level transitions: that expresses a full removal and insertion rather than preserving identities.
- For sorting/filtering over a substantial source model, a C++ `QSortFilterProxyModel` is a more natural model/view boundary; verify the source model/proxy reports row insert/remove/move signals rather than resets if animation continuity matters.

### Gaps
- Qt's docs do not prescribe a particular QML reconciliation algorithm for `ListModel`; correctness depends on stable keys, duplicate handling, desired ordering, and whether filter changes are batched.
- Quickshell `ScriptModel` is not a Qt Quick API and its unique-values constraint may not fit datasets with duplicate values. Check the version/API shipped by the application before adopting it.

## Repeater and Qt 6 safety caveats

### Takeaway
`Repeater` is not a drop-in animated substitute for `ListView`: it eagerly instantiates every delegate and has item-added/removed signals, but no view transition properties. A `Row`/`Column`/other positioner can animate its own add/remove operations, with different semantics and scalability. For Qt 6, prefer stable model identity, required delegate properties, and transitions based on actual model notifications.

### Cited Findings
- Qt says `Repeater` creates all delegate items when first created; for large models where only some rows need to be visible, consider `ListView`, which creates delegates as they are scrolled into view. Repeater also provides `itemAdded`/`itemRemoved` signals, not ListView's add/remove/move/populate transition properties. [Repeater](https://doc.qt.io/qt-6/qml-qtquick-repeater.html)
- Qt documents positioner add/remove transitions separately: they animate items added to or removed from a positioner, and setting opacity to zero alone does not remove an item from the positioner. [Positioner transitions](https://doc.qt.io/qt-6/qml-qtquick-transition.html)
- Qt warns ListView delegates may be destroyed or reused; do not store durable application state in a delegate. When `reuseItems` is enabled, model roles and index update on reuse, and delegate-local state may need resetting. [ListView: delegates and reuse](https://doc.qt.io/qt-6/qml-qtquick-listview.html#reusing-items)
- In Qt 6 QML, required properties provide explicit model-role bindings; Qt's model/view overview recommends them in most cases. `delegateModelAccess` is available since Qt 6.10, so do not assume it exists on earlier Qt 6 releases. [Models and Views: roles](https://doc.qt.io/qt-6/qtquick-modelviewsdata-modelview.html#models), [ListView API](https://doc.qt.io/qt-6/qml-qtquick-listview.html)
- Dynamic `ListModel` roles must be enabled before adding data, cannot be enabled for statically declared `ListElement`s, and incur a documented performance cost (typically 4–6x); keep role types consistent where possible. [ListModel: dynamicRoles](https://doc.qt.io/qt-6/qml-qtqml-models-listmodel.html#dynamicRoles-prop)

### Inferences
- For a normal search results panel, prefer `ListView` plus an incrementally updated model, with a short `remove` opacity transition, `add` opacity/scale transition, and `displaced` position animation. Ensure interrupted transitions restore properties such as opacity/scale to their intended steady-state values.
- Use `Repeater` with a positioner only for small, bounded collections that should all exist at once; avoid it for long/searchable result lists.

### Gaps
- Qt's positioner documentation describes transition support, but there is no single official recipe combining a live text filter, stable IDs, and animated reconciliation for a QML-only `ListModel`.
