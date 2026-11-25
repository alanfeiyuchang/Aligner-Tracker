# iPhone Duo

How Aligner Tracker lays out on the foldable, how that was checked, and how the
Duo App Store images are made. Measured on an `iPhone Duo` simulator (iOS 27.1,
Xcode 27.1), 2026-11-25.

## The canvases

| | points | what the system does |
|---|---|---|
| outer (folded) | 466 × 678, safe area 382 wide | Reserves an 84 pt strip on the trailing edge and moves the tab bar and the navigation-bar buttons into it, stacked vertically. |
| inner, held wide | 951 × 669 | Same trailing strip. Regular width. The app's portrait lock is ignored. |
| inner, upright | 669 × 951 | Tab bar back at the bottom, status items top right. |

Folding or turning the phone resizes the running scene; nothing is relaunched.
The app holds no sizes of its own, and the wide layouts below re-flow the same
views (`AnyLayout`), so navigation, sheets and scroll state survive a fold.

## What the app does differently

Nothing on the outer screen: it is narrower than an iPhone Pro Max and the
phone layout already fits beside the system's strip.

On the inner screen, `Support/AdaptiveLayout.swift` reacts to the **width the
view is given**, never to the device:

| width | effect |
|---|---|
| over 600 pt | Scrolling content (Home, History, diary entry, Settings) is capped at 600 pt and centred with `contentMargins`. Onboarding is capped the same way with a frame. |
| 700 pt and up | Home, History and the diary entry go two-column: ring \| tray + change button, stats + calendar \| selected day, photo \| details. Capped at 900 pt. |

The widest canvas an ordinary iPhone offers is 440 pt (portrait only) and the
Duo's outer screen is 466 pt, so below 600 pt every helper is inert: the margin
is `nil` (system default) and the layout is the same `VStack` as before. That
is the whole guarantee that phones are untouched — keep new thresholds above
466 pt.

The Diary grid was already adaptive (150 pt minimum columns) and the Change
Aligner sheet is a system form; neither needed changes. Widgets get their size
from the system and needed none.

## Checking it without opening a simulator window

`Support/ScreenshotSeed.swift` (DEBUG only) loads a fixed data set and opens a
given screen when the app is launched with `SIMCTL_CHILD_ALIGNER_SHOT=<mode>`:
`home`, `history`, `diary`, `settings`, `change`, `entry`, `onboarding`,
`onboarding2`, `onboarding3`. Add `SIMCTL_CHILD_ALIGNER_SHOT_RUNNING=1` for a
running timer. Seeded launches skip notification scheduling.

```bash
U=<simulator udid>
xcrun simctl status_bar $U override --time "9:41" --batteryState charged --batteryLevel 100
for m in home history diary settings change entry onboarding onboarding2 onboarding3; do
  xcrun simctl terminate $U ACM.Aligner-Tracker
  SIMCTL_CHILD_ALIGNER_SHOT=$m xcrun simctl launch $U ACM.Aligner-Tracker
  sleep 4
  xcrun simctl io $U screenshot --display 1 $m.png   # Duo: 1 = outer, 3 = inner; omit on a phone
done
```

`simctl` cannot fold the Duo or turn it. Claude Code's iOS Simulator tool can,
headlessly (`set_posture` closed/open, `rotate`); otherwise use DeviceHub.

Checked on 2026-11-25, all nine modes on the outer screen and on the inner
screen both ways up, plus fold → unfold with a diary entry and an onboarding
page open, and the small and medium widgets on both home screens. On an
iPhone 17 Pro the same nine screens were captured from a build without the
layout changes and from this one: identical apart from the system's home
indicator fade and glass shimmer, which differ between two runs of one build
too.

Not checked: Lock Screen widgets (inline / circular / rectangular), the camera
and photo picker, the share sheet, Split View on the inner screen, a real
device.

## App Store images

`AppStore/screenshots/duo/` — see the header of `make_duo_screenshots.swift`
there. Raw captures go in `raw/{outer,inner,inner-landscape}/` using the loop
above with `home history diary settings` and the running timer, then:

```bash
cd AppStore/screenshots/duo && swift make_duo_screenshots.swift
```
