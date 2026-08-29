# Xcode Cloud — build & archive

Xcode Cloud keeps its workflows in App Store Connect, not in this repository,
so there is no workflow file here to edit. What the repo can control is
already in place; the rest is a one-time click-through that needs your Apple
ID, which is why it is written out below rather than scripted.

## What is already done

| Requirement | State |
|---|---|
| A **shared** scheme that archives | `Aligner Tracker.xcscheme` in `xcshareddata/xcschemes`, Archive action on Release |
| The scheme actually archives | Verified: `ARCHIVE SUCCEEDED`, app and widget both `1.1 (1)` |
| App and extension versions agree | `MARKETING_VERSION` / `CURRENT_PROJECT_VERSION` are defined once on the project; every target inherits them |
| A test target CI can run | `AlignerTrackerTests`, wired into the shared scheme's Test action |
| Build numbers that do not collide | `ci_scripts/ci_pre_xcodebuild.sh` stamps `CI_BUILD_NUMBER` into `CURRENT_PROJECT_VERSION` |

`ci_scripts/ci_pre_xcodebuild.sh` is a no-op outside Xcode Cloud, so local
builds keep the committed build number. Delete it if you would rather set the
build number by hand.

## Creating the workflow

Xcode Cloud needs an Apple Developer Program membership (you have one) and
access to the GitHub repository. In **Xcode**:

1. **Product → Xcode Cloud → Create Workflow**.
2. Pick **Aligner Tracker** as the product. Xcode lists the shared scheme; if
   it does not appear, the scheme lost its "Shared" tick in
   *Product → Scheme → Manage Schemes*.
3. Grant App Store Connect access when prompted, then let Xcode connect to
   `alanfeiyuchang/Aligner-Tracker`. GitHub will ask you to install the Xcode
   Cloud app on the repository — this is the step that cannot be automated.
4. Edit the workflow:

   - **Start Conditions** — *Branch Changes* on `main`. Leave pull request
     builds on if you want checks on PRs.
   - **Environment** — the latest release Xcode. macOS version: default.
   - **Actions** — add two:

     | Action | Settings |
     |---|---|
     | **Build** | Scheme `Aligner Tracker`, platform iOS |
     | **Archive** | Scheme `Aligner Tracker`, platform iOS, **deployment preparation: none** |

     "Deployment preparation: none" is what keeps the archive from being sent
     anywhere. Signing is managed by Apple, so there are no certificates to
     configure.

   - **Post-Actions** — leave empty. Adding *TestFlight Internal Testing*
     here is what turns this into a distributing pipeline later.

5. Save. The first run starts on the next push, or from
   **Product → Xcode Cloud → Manage Workflows → Start Build**.

Adding a third **Test** action running the `Aligner Tracker` scheme on an
iOS simulator will run `AlignerTrackerTests` on every push. Worth doing —
`WearMathTests` is what stops the wear-time day-boundary bug coming back.

## When you do want to distribute

Two changes, both in the workflow, none in this repo:

1. Archive action → deployment preparation → **TestFlight (Internal Testing
   Only)** or **App Store Connect**.
2. Add a **TestFlight Internal Testing** post-action and pick the tester
   group.

Build numbers are already unique per build, so uploads will not be rejected
for a duplicate.

## Where builds show up

*Report navigator → Cloud* in Xcode, or App Store Connect → the app →
**Xcode Cloud**. Archives are downloadable from the build's page.
