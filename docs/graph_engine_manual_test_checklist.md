# Graph engine manual regression checklist

Run the following checks on at least one phone-sized target and one wide target.
Use each expression independently, then repeat with all five graph slots filled:

```text
(1/30)^x + e^(x/4)
e^x
e^(x^2)
1/x
tan(x)
log(x)
sqrt(x)
sin(100x)
1/(x-2)
x^10
```

For every expression:

- Draw at the default range, switch Y from Auto to Manual, and apply `-10 / 10`,
  `-2 / 20`, and `-1e6 / 1e6`.
- Change X to `-100 / 100`, `-1000 / 1000`, and back to `-10 / 10`.
- While editing each bound, leave it empty and enter `-`, `.`, `-0.`, `1e999`,
  equal min/max values, reversed values, and a range smaller than the documented
  minimum. The existing graph must remain visible and unchanged; Apply must show
  controlled feedback.
- Tap Apply repeatedly with different valid X ranges. Only the final debounced
  range should become the sampled result.
- Zoom, pan, double-tap reset, apply manual bounds, switch back to Auto Y, and use
  Reset view. No path should bridge a reciprocal or tangent asymptote.
- Confirm that progress indicators remain animated while sampling and that
  scrolling, text entry, and navigation remain responsive.
- Confirm invalid-domain areas (`x <= 0` for log, `x < 0` for sqrt, poles for
  reciprocal/tangent) are blank rather than connected or rendered as spikes.

Pass criteria: no crash, freeze, uncaught exception, non-finite chart coordinate,
or stale result after the progress indicator clears.
