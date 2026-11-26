# Animated search-result count changes in Qt Quick

## Which mechanisms animate container resizing versus delegate insertion/removal?

### Takeaway
Treat the search panel's outer height as its own animated property, driven by a content-height target. Separately, use view/positioner transitions for rows that are inserted, removed, or displaced; neither mechanism substitutes for the other.

### Cited Findings
- A `Behavior` animates every change to its target property; Qt's example applies a `NumberAnimation` whenever a `Rectangle.width` changes. The same pattern applies to a panel's explicit `height`. — [Behavior QML Type](https://doc.qt.io/qt-6/qml-qtquick-behavior.html)
- `implicitHeight` expresses an item's preferred content size, but an explicit `height` remains the actual rendered size outside a layout. Within a Qt Quick Layout, the layout controls size and explicit `height` is ignored; use `implicitHeight` / `Layout.preferredHeight` as appropriate. — [Item QML Type](https://doc.qt.io/qt-6/qml-qtquick-item.html); [Layout QML Type](https://doc.qt.io/qt-6/qml-qtquick-layouts-layout.html)
- `ListView.add` animates newly added delegates; `addDisplaced` (or generic `displaced`) animates existing delegates moved by an addition. `remove` animates removed delegates, while `removeDisplaced`/`displaced` animates the remaining rows moving into the gap. — [ListView QML Type](https://doc.qt.io/qt-6/qml-qtquick-listview.html)
- A view's `add` transition is not used for initial population or a wholesale model replacement/reset; those use `populate`. Qt specifically warns against animating a new delegate's height inside `add`, because following delegates are laid out at the wrong position; animate height in the delegate's `onAdd` handler if that is needed. — [ListView QML Type](https://doc.qt.io/qt-6/qml-qtquick-listview.html)
- `Row`, `Column`, `Grid`, and `Flow` positioners also offer `add` and `move` transitions; `move` includes items displaced when another child is removed or resized. — [ViewTransition QML Type](https://doc.qt.io/qt-6/qml-qtquick-viewtransition.html)
- Qt cautions that recalculating layouts continuously during animation can cost performance; for pixel-precise animated interfaces, bindings or direct item geometry may be preferable to a layout. — [Scalability](https://doc.qt.io/qt-6/scalability.html)

### Inferences
- Keep two separate values/concepts: a content-derived target height, and the panel's currently animated height. Bind the notch/background shape to the latter, so the outline tracks the visible expansion frame-by-frame rather than jumping to the final row count.
- For a small launcher result set, a fixed first row plus an extra-results container is a good fit: its target height is `extraCount * rowPitch` (plus spacing), with `Behavior on height` and `clip: true`; keep the first row outside this changing region. Animate the notch to the same effective visible-content height, including fixed input/first-row/padding.
- Clipping is necessary during a height reveal, but by itself can look like a crop. Pair it with a small opacity/vertical-entry animation on newly revealed rows and smooth panel-height change. Keep the input and first result stationary to preserve visual anchors.
- If rank ordering changes and rows are represented in a `ListView`, preserve stable identity and update the model incrementally where practical. Then use `move`/`displaced` for rank movement, plus `add`/`remove` for membership changes. Wholesale reset can instead appear as replacement/population and lose continuity.
- For just a few rows, a `Column`/`Repeater` can be simpler than a `ListView`; positioner `move` transitions can animate children moving as the visible set changes. Avoid applying both a positioner transition and custom y animation to the same movement.

### Gaps
- Qt documents the mechanics but does not prescribe a universal duration/easing or a canonical search-launcher design. The suggested short duration and restrained easing should be tuned in the actual notch/compositor.
- No public Qt/Quickshell demo found that exactly combines a fixed search input, pinned first result, rank-on-every-keystroke filtering, and a notch-shaped surface whose height follows animation.

## How should a live-ranked launcher avoid redraw-like content swaps, and where do crossfades fit?

### Takeaway
Prioritize continuity of geometry and identity: keep the search field and first result fixed, animate the panel's height, and animate row insertion/removal/reordering independently. Use crossfades only for content that truly changes in place; a crossfade alone does not animate layout or preserve spatial continuity.

### Cited Findings
- Qt describes property animations as interpolation between values, and `Behavior` as the default animation for property changes. — [Animation and Transitions in Qt Quick](https://doc.qt.io/qt-6/qtquick-statesanimations-animations.html); [Behavior QML Type](https://doc.qt.io/qt-6/qml-qtquick-behavior.html)
- `ListView` transitions distinguish added, removed, and displaced delegates. Removed delegates can fade/move out, but the docs explicitly say this transition does not animate the other items moving into their new positions; configure `displaced` or `removeDisplaced` separately. — [ListView QML Type](https://doc.qt.io/qt-6/qml-qtquick-listview.html)
- Qt's `Behavior` documentation includes a custom behavior that fades a target out, applies a property change, and fades it back in, demonstrating crossfade-like treatment of a changed property. — [Behavior QML Type](https://doc.qt.io/qt-6/qml-qtquick-behavior.html)
- Qt's Tweet Search example is a concrete search-result UI using a `ListView` and an `add` transition, though it is a network-backed feed and does not demonstrate a pinned first result or a dynamically resizing notch. — [Qt Quick Demo — Tweet Search](https://doc.qt.io/archives/qt-5.12/qtdoc-demos-tweetsearch-example.html); [tweetsearch.qml](https://doc.qt.io/archives/qt-5.12/qtdoc-demos-tweetsearch-tweetsearch-qml.html)

### Inferences
- Recommended Quickshell pattern:
  1. Keep the input and first-ranked result in stable, non-recreated items.
  2. Show only a small capped number of additional results; compute the desired height from the visible result count, row pitch, spacing, and fixed chrome.
  3. Animate the panel's explicit height toward that target. Bind the notch surface geometry to the panel's current animated height, not the target.
  4. Animate extra row adds/removes with restrained opacity plus a few-pixel y/scale reveal, and animate displacement/reordering separately. Use stable result IDs to distinguish a moved result from a different result occupying the same index.
  5. For an in-place text/icon swap where the row identity is intentionally unchanged, a brief crossfade can soften the update. Avoid crossfading the whole list on every keystroke: that obscures ranking changes and can look like redraw/flicker rather than movement.
  6. Ensure the visible clip region follows the animated panel bounds; don't leave a fixed-height viewport that cuts rows while the notch has already resized (or vice versa).
- Since ranking/filtering happens per keystroke, long independent row animations will overlap and lag behind the current query. Use short, interruptible transitions that retarget from the current visual value, and avoid animating every unchanged delegate's opacity. If results churn too quickly, animate only the panel height and meaningful row movement, with no enter/exit effect for tiny per-keystroke changes.
- If the model is rebuilt/reset on each keystroke, view add/remove transitions may not preserve continuity: Qt documents reset/replacement as population behavior. An incremental diff based on stable IDs is the better foundation for semantic movement transitions.

### Gaps
- The Qt docs explain crossfade ingredients and view-transition semantics, but no source found provides measured UX evidence comparing crossfade-only versus geometry/membership animation for a live search launcher.
- Quickshell-specific documentation/demo for a morphing notch surface synchronized to an animated result list was not located; recommendation applies standard Qt Quick property and view transitions.
