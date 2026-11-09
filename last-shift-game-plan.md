# Last Shift First Playable Game Plan

Version 1.0 | November 8, 2026 | Implementation baseline

Build a complete, winnable Godot prototype about keeping an aging cargo ship alive long enough to escape. The core experience is pressure, a meaningful decision, hands-on action, and visible relief. This plan defines the first playable and the evidence needed before expanding it.

## 1 Premise and creative direction

You are finishing your last shift aboard an aging cargo ship when a jump goes wrong. The crew has evacuated. Your escape pod is dead.

Your way home is the ship itself: **repair and charge the jump drive before the ship becomes uninhabitable.**

You know this ship: its shortcuts, unreliable equipment, and improvised repairs. That familiarity becomes your advantage. The title carries two meanings: this was meant to be your last shift in this job; now it may be your last shift at all.

**Player promise:** a tense emergency that feels understandable and survivable. Repairs matter. Mistakes hurt without routinely ending the run. Winning feels like bringing a battered machine home through your own decisions.

The emotional progression is: familiarity, disruption, growing competence, difficult tradeoffs, a final push, and release. There are quiet stretches during which the player can hear the machinery working again.

### First playable scope

| Item | Decision |
| --- | --- |
| Format | Single-player top-down 2D survival and repair game |
| Engine | Godot 4 stable release, GDScript, Compatibility renderer |
| Delivery | Downloadable Windows desktop build; Linux development support |
| Run | One authored scenario targeting 8 to 12 minutes on a successful first completion |
| Ship | Five rooms, a central corridor, one optional cargo shortcut |
| Systems | Power allocation, heat, finite air reserve, jump charge |
| Incidents | One coolant fault and one hull leak |
| Recovery | Persistent repairs, preserved charge, one emergency air reserve |
| Ending | Manual jump from the bridge; explicit failure and immediate retry |

The ordinary opening is included in the duration target. Replays may be shorter. These durations are tuning targets, not deadlines imposed on development or guarantees of player behavior.

### Design priorities

- **Readable danger:** what is wrong, what it affects, and the available response are clear.
- **Lasting progress:** fixing a problem improves the situation for the rest of the run.
- **Earned recovery:** a wrong turn or interrupted repair usually leaves a credible recovery path.
- **Cohesive feedback:** machinery, displays, lighting, and sound report the same underlying state.

Success is a player thinking, "I know what I would do differently. Let me try again."

## 2 Opening and authored scenario

### Ordinary work before the emergency

Begin with a short maintenance checklist in a functioning ship. Teach movement and interaction by reseating a service connector and making one safe power change. This uses the same interaction behavior as later repairs and introduces no extra inventory system. Lethal resource depletion is inactive during this opening.

The jump then fails. Use a brief lighting change, a restrained camera impulse, and evacuation announcements. The player is isolated in the service section while the crew evacuates; their assigned maintenance pod fails its launch check. Deliver this through sound and terminal text, without animated crew or a playable evacuation sequence.

Show these messages in order:

> CREW EVACUATION COMPLETE
>
> MAINTENANCE POD: LAUNCH FAILURE
>
> ONE LIFE SIGN REMAINING

The objective changes to **Get home.** Its actionable subtask is **Restore cooling, then charge the jump drive.** Start emergency resource simulation when control returns; transitions do not consume the response window.

### Emergency progression

| Beat | Trigger and action | Result |
| --- | --- | --- |
| Coolant fault | Emergency begins; salvage a cargo motor and install it in the pump | Cooling can run; drive charging interlock clears |
| Recovery | Pump repair completes | Cooling resumes if powered; warning clears as heat falls |
| Hull leak | First time charge is at least 30%, cooling is repaired, heat is below warning, and 40 seconds of active play have passed since repair | A short warning precedes an accessible leak in Cargo |
| Stabilization | Player patches the leak, reallocates power, or uses the reserve | Air loss slows and margin can recover |
| Final push | First time charge reaches 70% | Objective and music advance; no additional fault is created |
| Escape | Charge reaches 100%; player operates bridge control while alive | Jump succeeds; resource simulation stops |

The percentages and 40-second interval are initial settings. The order and prerequisite-based pacing are design commitments. Each incident can fire only once. If prerequisites are unmet, an incident waits; it never becomes an overdue backlog of failures.

The leak must be reachable with the equipment already available. Players may choose to endure it and race to escape rather than patch it. Test that shortcut as a legitimate risky strategy, not an automatic win or an arbitrary prohibition.

At full charge, prominently show **RETURN TO BRIDGE - JUMP READY**. Charge is retained and its power draw stops, freeing power for survival on the final walk. Arrival still matters because air and heat continue until the jump is activated.

After escape, alarms stop, the ship settles, and the terminal reads **SHIFT COMPLETE**. A short results screen offers replay and quit. Retry defaults to the emergency start, with an option to replay the opening.

## 3 Ship layout and player actions

Use a compact ship with recognizable room silhouettes and a corridor that never becomes impassable. Measure route times in the walkable prototype before setting lethal thresholds. Important destinations should initially be about 10 to 20 seconds apart.

| Room | Equipment and role | Visual landmark |
| --- | --- | --- |
| Bridge | Final jump control, objective display | Forward viewport and helm |
| Engineering | Power console and coolant pump | Large pump and bright conduits |
| Life Support | Air display and one emergency reserve | Cylinder bank and fans |
| Cargo | Salvage donor, later hull leak, optional shortcut | Crates and loading machinery |
| Jump Chamber | Drive arming control and charge display | Large circular drive assembly |

All five rooms connect to the permanent corridor. A separate cargo service shortcut connects Cargo to Engineering. Salvaging the donor motor disables that shortcut and its work light, but the main route remains lit and accessible. Explain the cost before the player confirms salvage.

### Controls and interaction

Default controls are WASD or arrow keys to move, E to interact, Q to drop the carried component, and Escape to pause. On-screen console buttons also accept keyboard focus and activation. Store actions in Godot Input Map so bindings can be changed later.

- Highlight one nearby usable target and show its name, action, and relevant cost.
- Carry at most one component, visible on the character or HUD. No inventory grid.
- Salvage one motor from cargo equipment, carry it to Engineering, and install it.
- Patch the leak with the built-in repair tool; no consumable patch inventory.
- Repairs use a short progress interaction. Holding or a toggle-to-work option is supported; no rapid tapping or precision minigame.
- Leaving range or canceling stops work but preserves completed progress. Installation consumes its component only on successful completion.
- Components can only be dropped at reachable positions. Their placement cannot block a doorway or put them outside the ship.

Engineering controls the three power consumers. The jump drive must first be armed at its local panel; it then charges automatically whenever valid power is allocated. Basic movement, emergency lighting, the repair tool, and manual controls remain usable without consumer power.

The power panel shows current allocation, demand, and the effect of each consumer. An allocation that would exceed capacity is rejected with a clear explanation; it never silently turns off another system.

A compact HUD shows objective, air reserve, heat and trend, jump charge, and power allocation. Room signs and an accessible static ship map support navigation. No rotating minimap or navigation upgrade system is needed.

## 4 System rules and outcomes

Keep one authoritative simulation. Displays and machines reflect it rather than maintaining separate copies of resource values. Power allocations and incident changes are deterministic; frame rate must not change depletion or charging rates.

### Power and tradeoffs

| Consumer | Initial demand | Powered behavior | Unpowered behavior |
| --- | --- | --- | --- |
| Life support | 2 units | Slows air reserve consumption | Air is consumed faster |
| Cooling | 2 units | Repaired pump removes heat | Heat rises more quickly |
| Jump drive | 4 units | Armed, available drive charges | Charge pauses and is retained |

Initial reactor capacity is **6 units**; total demand is 8. This is a balance experiment. Charging with cooling accepts faster air loss; charging with life support accepts more heat. Pausing charging allows both survival systems to run.

There is no reactor overdrive, fuel model, circuit-routing puzzle, or separate battery in this prototype. The cooling repair gates drive availability so the first repair has a necessary and obvious purpose.

### Air and heat

Represent air reserve, heat, and charge as normalized values from 0 to 100. Air has a finite baseline drain even with life support powered. The leak adds a separate drain; patching removes that addition permanently. The reserve adds a fixed, configurable amount of air once, capped at 100, and clearly reports the actual gain before use.

Heat combines idle generation, charging load, and powered cooling. Tune repaired cooling to produce visible recovery when charging is paused. A high-heat warning appears before an automatic charging cutoff. At cutoff, show that the drive is cooling down and stop its power draw; resume its availability only below a lower restart threshold. Previously assigned drive power is released and must be deliberately reassigned, so recovery does not unexpectedly consume power.

Sustained critical heat can destroy the ship after a visible grace countdown. Cooling below the critical recovery threshold resets this countdown. Use separate enter and clear thresholds to prevent flickering warnings. Do not create new equipment failures from heat in version 1.

### End conditions

- **Win:** charge is 100, the player reaches the bridge and activates jump, and no terminal failure has occurred.
- **Lose:** air reaches 0, or the critical-heat grace countdown expires.
- **Deterministic order:** resolve terminal resource conditions before accepting a jump in the same simulation tick. Communicate the countdowns so the result is understandable.
- **Pause:** stops resource changes, incident delays, repair progress, and grace countdowns. Menus remain responsive.
- **Restart:** restores resources, incidents, components, doors, UI, sound, and controls to the selected starting state.

Failure identifies the actual cause and a context-relevant recovery action. Do not blame a missing action the player already completed. Mid-run saves are outside this prototype; settings may persist.

## 5 Difficulty and pacing contract

Difficulty comes from competing priorities and limited time. It must not depend on repeatedly undoing completed work. The authored coolant fault and leak are permanent repairs; no random fault generator exists in this version.

### Starting tuning hypotheses

| Measure | Initial target |
| --- | --- |
| Safe ordinary opening | About 45 to 60 seconds; player paced if slower |
| First repair recovery interval | At least 40 seconds of active play before leak eligibility |
| Warning response allowance | At least twice the measured direct response time |
| Required response time | Notice and understand, travel, interact, and see confirmation |
| Early urgent faults | One |
| Later urgent pressures | At most two clear priorities; one highlighted as most urgent |
| Successful first completion | About 8 to 12 minutes including opening |
| Expected mistake tolerance | A wrong turn plus an interrupted repair remains recoverable |

Choose depletion rates only after the layout and interaction durations are measured. Keep all values in one balance profile, including air drains, leak drain, reserve amount, heat rates, charge rate, repair durations, warning thresholds, grace period, and incident gates.

### Recovery must be real

Repairing the pump enables cooling and lowers heat when powered. Patching the leak slows visible air loss. Using the reserve adds a meaningful amount of time. Pausing the drive preserves progress. Reaching full charge frees power for the trip to the bridge.

Show those benefits immediately through trends, sounds, and equipment behavior. A repair that technically succeeds but leaves the player unable to perceive improvement needs clearer feedback or stronger relief.

The scenario controller delays only authored incidents using the documented prerequisites. It does not secretly refill resources, alter drain rates, or suppress the consequences of choices. Resource pressure continues during recovery intervals, so they provide room to act rather than invulnerability.

### Balance traps to check

- **One dominant setting:** if one power allocation always wins comfortably, strengthen the relevant tradeoff or change timing before adding another mechanic.
- **Unavoidable failure:** inspect the complete warning-to-response route, not only the repair duration.
- **Waiting forever:** finite baseline air drain prevents indefinite stabilization; test that waiting is costly without forcing frantic movement throughout.
- **Death spiral:** avoid damage that disables the player's ability to repair the very cause of that damage.
- **False urgency:** do not use critical alarms or red warning states when the simulation is safe.
- **Punishing competence:** progressing quickly should not trigger an immediate pileup of incidents.

Do not chase a particular win percentage from a tiny test group. First establish that players understand events, can recover, and want another attempt. Tune after each observed problem, changing a small number of variables at a time.

## 6 Cohesive presentation

The ship is an aging industrial workplace: worn metal, chunky controls, exposed conduits, practical labels, and warm work lights. Use a simple consistent 2D style with readable silhouettes. Early art can be geometric, but interaction language and system feedback must work from the first prototype.

| State | Visual behavior | Audio behavior |
| --- | --- | --- |
| Working | Steady indicator, moving machinery, clear label | Stable mechanical hum |
| Strained | Amber indicator, distinct icon, readable cause | Intermittent warning |
| Critical | Red indicator, explicit action prompt and countdown where relevant | Highest-priority alarm |
| Recovered | Stable indicator and resumed machine motion | Confirmation, then quieter ambience |

Color always has a label, shape, or animation partner. All HUD values, machine screens, and effects use the same system state. Distinguish OFF, BROKEN, COOLING DOWN, and READY rather than presenting every unavailable device as a failure.

### Sound and tension

Use separate audio buses for ambience, machinery, alerts, interface, and music, with exposed user volume controls. Spatial machine sounds help orient the player. Limit repeating alert competition: the highest-priority alert dominates, while lower-priority issues stay visible.

The late-run music layer can follow progress toward escape. Hazard alarms follow actual danger. A faster soundtrack must not imply an unseen failure timer. Recovery should be audible: the warning ends, fans resume, and the ship becomes easier to listen to.

### Readability and accessibility

- Keep emergency routes and interaction prompts legible when machinery loses power.
- Use the same icons and terminology on the map, equipment, HUD, and prompts.
- Present evacuation announcements and meaningful sound cues as text as well.
- Support pause, adjustable audio, reduced flashing, reduced camera shake, and toggle-to-work repairs.
- Avoid rapid repeated flashes. Camera effects never obscure controls or required information.
- Check UI at 1280 by 720 and 1920 by 1080, with practical scaling and no cropped prompts.

### Minimum presentation assets

One player with idle, movement, and repair states; five room landmarks; a reusable equipment indicator; one carried motor; a leak effect; door open and closed states; a consistent HUD and font; simple machinery loops; warning and repair sounds; and a restrained opening and ending transition.

Keep an asset source and license record. Use original or appropriately licensed placeholders. The prototype should feel like one workplace even before detailed artwork arrives.

## 7 Godot architecture and development setup

Use one verified stable Godot 4 release and matching export templates, pinned for the project. The implementation task selects the exact release from official downloads and records it; a floating latest version is not a reproducible setup. GDScript and the Compatibility renderer are the baseline.

### Responsibilities

| Component | Owns |
| --- | --- |
| RunController | Opening, emergency, victory, failure, pause and restart |
| ShipSimulation | Authoritative resources, allocations, rates and thresholds |
| ScenarioController | One-shot incidents, prerequisites and progression flags |
| Player and Interactable scenes | Movement, target selection, carrying and repair actions |
| Equipment scenes | Local controls and feedback derived from simulation state |
| HUD and AudioController | Presentation, warning priority and accessibility options |
| BalanceProfile Resource | Central editable tuning values and scenario parameters |

Use signals for state changes and Resource files for configuration. Keep the simulation testable without rendered scenes. A small fixed-step update or equivalent deterministic time integration should support reproducible scripted runs. Visual effects interpolate independently.

### Suggested repository layout

Keep the Godot project under `game/`, development helpers under `scripts/`, design and playtest notes under `docs/`, and automated simulation checks under `tests/` or a clearly documented in-project test location. The exact split can follow the chosen minimal test approach.

Commit the project, source assets, export presets, dependency pins, and documentation. Ignore Godot caches, generated builds, and machine-specific files. Keep the downloadable Windows build out of ordinary source commits.

### Establish the build path early

Milestone 0 must produce a repeatable Linux/cloud setup and a native Windows setup, an engine version check, clean headless import, a short startup smoke run, and a Windows export using matching templates. Validate native launching on Windows when available. Headless success does not establish visuals, audio, controls, or difficulty.

Create a repository-owned setup script that is safe to rerun and uses official, checksum-verified downloads. Document the command only after that script exists and passes. If environment setup is configured before the first code task, do not point it at a nonexistent repository script.

Godot documents headless operation and command-line exports in its command-line tutorial. Use current documentation for the pinned version rather than copying a command blindly. The official OpenAI documentation explains environment setup behavior; follow the environment actually selected for the project.

Include developer-only controls to reset a run, jump to a scenario beat, inspect values and rates, and capture a local event log. Debug controls must be disabled in the player build. Logs remain local; no analytics service is required.

## 8 Milestones and review gates

Implement in small reviewable changes. Each milestone should leave a runnable project and a brief note describing the outcome, checks, and remaining playtest questions. These are dependency-ordered milestones, not calendar estimates.

### M0 Reproducible foundation

Create the Godot project, dependency pins, repeatable development setup, build helpers, basic continuous checks, README, and Windows export preset. Add this plan to the repository. Respect any existing repository instructions and review policy.

**Exit evidence:** clean import and startup, version checks, an exported Windows build, and precise local launch instructions. Record any native-launch validation still required.

### M1 Walkable ship

Build the five-room layout, permanent corridor, optional shortcut, movement, target prompts, carrying, and a pump repair. Add basic map, room labels, and functional placeholder feedback.

**Exit evidence:** a player can find the motor, understand the salvage cost, carry it, repair the pump, and return by the permanent route. Dropping or canceling cannot strand the component. Measure traversal and repair durations.

### M2 Working systems

Implement power, heat, air, charge, drive arming, reserve use, pause, and the shared state model. Add the developer overlay and tuning profile.

**Exit evidence:** resource accounting and threshold checks pass; scripted careful and aggressive approaches can both escape under a documented candidate profile. Confirm that visuals reflect the actual state. Scripted wins do not yet prove human fairness.

### M3 Complete authored run

Add the ordinary opening, emergency transition, gated coolant and leak sequence, end conditions, final bridge action, results, and retry.

**Exit evidence:** the run can be completed, lost by either failure cause, paused, and restarted repeatedly without stale state. Each incident fires once and repaired faults stay repaired.

### M4 Difficulty and recovery

Playtest careful, aggressive, and imperfect approaches. Tune warning windows, travel burden, grace periods, reserve value, and the length of calm stretches.

**Exit evidence:** imperfect play has a demonstrated recovery route; players can explain a loss and identify their next adjustment. Record observed issues and the profile used.

### M5 Cohesion and readability

Unify room art, terminology, machine feedback, alert priorities, sound, HUD scaling, and opening/ending transitions. Add the agreed accessibility options and verify them.

**Exit evidence:** readable scenes at both target resolutions, understandable state without audio or color alone, perceptible relief, and no competing alarm wall.

### M6 First playable release candidate

Package the Windows build with controls, credits, version/source identity, known issues, and a short playtest guide.

**Exit evidence:** a fresh player can launch without the editor, play, reach an outcome, and retry. Record Windows playtest results separately from automated build results. Expand scope only after this gate.

## 9 Validation and acceptance checklist

### Automated behavior checks

- Power allocations never exceed capacity and never silently change unrelated consumers.
- Resource updates are stable across different frame rates and clamp valid ranges.
- Paused or interrupted charging retains charge; full charge releases its demand.
- Fault repair and canceled repair progress persist correctly; the motor is consumed once.
- Reserve use is capped, reported accurately, and cannot be repeated.
- Incident order, prerequisites, delay, and one-shot behavior hold.
- Overheat warning, cutoff, restart threshold, and grace countdown transition correctly.
- Pause stops every gameplay clock; restart resets every run-owned state.
- Terminal outcome ordering is deterministic and victory/failure fires once.

Keep tests focused on behavior and invariants. Avoid tests that merely reproduce implementation details. Clean imports and export checks should fail on actual script errors, not only a process exit code.

### Human playtest passes

| Pass | Behavior to observe | Question |
| --- | --- | --- |
| Careful | Repair promptly, stabilize, then charge | Can a clear plan produce a comfortable win? |
| Aggressive | Charge early and use air or heat margin | Is there a viable faster strategy with a real cost? |
| Imperfect | Take a wrong turn, interrupt work, react late once | Can the player recover without perfect execution? |
| Fresh player | Play without coaching beyond the in-game opening | Are the objective, tradeoffs, and feedback understandable? |

Log active-play time, scenario events, repairs, power changes, resource snapshots, reserve use, and outcome. Include build identity and balance profile. A short replay note should explain confusing moments and where relief was or was not felt.

Observe understanding, navigation, controls, and numerical pressure separately. Fix the actual source of frustration before making the resource budget easier. Compare only runs using the same profile, and record every tuning change with its intended effect.

### Acceptance of the first playable

- The agreed premise, opening messages, escape objective, and SHIFT COMPLETE ending are present.
- One complete run contains five rooms, two authored faults, one salvage cost, and one reserve.
- Careful and aggressive strategies can succeed; imperfect play has demonstrated recovery.
- Required paths remain accessible, and objectives cannot strand the player or a component.
- The player sees and hears a meaningful improvement after successful repairs.
- Both loss causes provide accurate feedback; retry is immediate and reliable.
- Settings, controls, readable warnings, pause, and target-resolution checks pass.
- The Windows package launches independently of the editor and includes credits and known issues.
- Automated checks, native launch checks, and human playtest observations are recorded distinctly.

## 10 Handoff and scope control

### Starting the repository

Copy this file to `docs/last-shift-game-plan.md` in the new repository. The Markdown version is the editable source of truth; the PDF is the reading copy. Update the document version and a short decision log when a deliberate design change is accepted.

Use the accompanying `START_HERE.md` for the package contents and `codex-kickoff.txt` as the first implementation prompt after the repository and cloud environment are ready. The first task is M0 and M1, ending with a runnable ship and a clear review handoff. Later milestones continue from that result.

### Fixed commitments and tuning freedom

The premise, 2D format, five-room ship, two authored faults, preserved repair/charge progress, finite air, recovery opportunities, and fair readable feedback define this prototype. Changes to those commitments should be explained as design changes rather than introduced silently.

Room dimensions, art details, component placement, input polish, power costs, rates, thresholds, warning windows, repair durations, and scenario percentages can be adjusted through playtesting. Record meaningful changes. Keep implementation naming and file structure practical rather than treating proposed class names as mandatory.

### Deferred work

Procedural maps, random breakdowns, combat, enemies, crew AI, multiplayer, inventory grids, crafting trees, multiple ships, progression, leaderboards, mid-run saves, VR, mobile export, physical controllers, and backend services are outside the first playable. Reactor overdrive, fire, venting individual rooms, and detailed pressure simulation are also deferred.

Do not add a new system to solve a problem that timing, layout, feedback, or a balance change can address. Keep work focused on the complete playable loop.

### Reference links

These sources support the implementation approach. Gameplay rules and numerical targets above are project design decisions to validate in the prototype.

- [Godot scene organization](https://docs.godotengine.org/en/stable/tutorials/best_practices/scene_organization.html)
- [Godot signals](https://docs.godotengine.org/en/stable/getting_started/step_by_step/signals.html)
- [Godot Resources](https://docs.godotengine.org/en/stable/classes/class_resource.html)
- [Godot command line and headless exports](https://docs.godotengine.org/en/stable/tutorials/editor/command_line_tutorial.html)
- [Official OpenAI documentation for environment setup](https://learn.chatgpt.com/docs/environments/cloud-environment)

### First implementation outcome

A new developer should be able to prepare the project, open the ship, move between rooms, salvage and carry the motor, repair the pump, and export a Windows build. The next milestone turns that foundation into the survival simulation. The goal remains a tense, possible, cohesive escape that makes the player want another shift.
