# Living City NPC Roadmap

This is the execution plan for the two open "living district" tasks in
[`ROADMAP.md`](ROADMAP.md):

- road network graph + traffic system;
- pedestrian crowds with navigation, reactions, and invisible streaming.

The target is systemic believability comparable to a mature AAA open-world
game, built from original code, content, characters, and map data. The goal is
not to copy another game's scripts or authored scenarios. It is to make the
player consistently believe that nearby people and drivers had somewhere to
be before the player arrived, noticed what happened, and continued afterward.

## What "alive" means

A nearby NPC must always have five explainable layers:

1. **Identity**: stable traits, role, home area, preferred transport, and memory.
2. **Intent**: a schedule, need, job, errand, social activity, or incident response.
3. **Route**: a legal path through sidewalks, crossings, lanes, junctions, and POIs.
4. **Reflex**: immediate avoidance and reactions to people, cars, danger, and blockage.
5. **Continuity**: recovery after interruption and plausible off-screen progress.

Random wandering alone does not satisfy this bar. More agents also do not make
the city more believable if they walk through walls, ignore traffic, or vanish
while visible.

## Current baseline

The repository already contains much of the decision math, but the live Miami
scene does not connect it into one simulation.

| Area | Existing foundation | Main gap |
| --- | --- | --- |
| Crowd streaming | `CrowdDirector` streams up to 40 nearby bodies | Miami spawns the basic `Pedestrian`, not the richer `Citizen`; visibility-safe spawn/despawn is not guaranteed |
| Pedestrian motion | `NpcBrain`, `NpcSteering`, `NavGrid`, `PathSmoother` | Basic peds wander directly; local avoidance, crossings, queues, and blocked-path recovery are not live |
| Daily life | `Citizen`, `CityDirector`, `NpcSchedule`, `NpcNeeds`, `NpcMind`, POIs | Proven in isolated probes, but not wired into the playable district |
| Reactions | `NpcReaction`, `NpcMemory`, `CrowdPanic`, `CrimeWitness`, `SoundPropagation` | Separate models do not share a live perception/incident pipeline |
| Road data | `RoadNetwork` builds a graph from district roads | It is centerline-based, has no lane/turn/stop-line semantics, and is not the live traffic source |
| Ambient traffic | `TrafficDirector`, `TrafficCar`, `TrafficFlow` | Cars use straight or generic grid routes, have no junction behavior, and change speed abruptly |
| Traffic rules | `TrafficSignal`, `TrafficRules`, native `TrafficModel` IDM | Tested foundations are not wired into Miami traffic |
| Performance | quality multipliers, streaming directors, native crowd/traffic primitives | No end-to-end budget by simulation tier; render, animation, AI, and physics costs are not measured together |

The first rule of this roadmap is therefore **integrate before inventing**.
Every milestone must make behavior visible in the playable district, not only
add another unit-tested model.

## Architecture direction

### Shared semantic world

People and vehicles must use one streamable semantic description of a tile:

- road lanes, directions, speed limits, and turn connections;
- junction conflict zones, stop lines, signals, and yield rules;
- sidewalks, curb edges, crossings, stairs, and pedestrian-only links;
- parking spaces, vehicle spawn portals, and despawn portals;
- typed POIs with capacity and activity slots;
- incident-safe pull-over, flee, and responder approach points.

Each world tile owns its data. Cross-tile links use stable IDs and are resolved
by the streaming layer; agents never hold fragile cross-scene node paths.

### Agent layers

Use composition and keep the runtime node thin:

```text
perception -> reflex -> intent -> route -> locomotion/action -> animation
                   \-> memory and incident reporting
```

- Pure `RefCounted` models decide state and remain deterministic in tests.
- Scene nodes sample Godot physics/navigation and apply the chosen action.
- A local world coordinator publishes incidents and semantic queries. It is not
  an autoload.
- Pedestrians and drivers share perception, memory, identity, incidents, and
  simulation-LOD concepts, but keep separate locomotion models.

### Simulation levels

The same agent identity moves between levels without becoming a different NPC:

| Tier | Typical range | Simulation |
| --- | --- | --- |
| A: full | visible/near player | physics, perception, local avoidance, animation, reactions every frame |
| B: reduced | resident but not important | route progress and decisions at 5-10 Hz, simplified avoidance/animation |
| C: virtual | off-screen tile | schedule/trip/incident state at 0.2-1 Hz, no scene node |

Promotion reconstructs position from a valid route or activity slot. Demotion
stores identity, intent, route progress, vehicle, and relevant memory. An agent
must never teleport, duplicate, or visibly pop because its tier changed.

## LC0 - Observe and reproduce

**Goal:** make the current unnatural behavior measurable before replacing it.

- [ ] Add an opt-in living-city debug overlay: agent ID, simulation tier,
      state, intent/reason, destination, route index, speed, blocker, fear, and
      current incident.
- [ ] Add counters for stuck agents, replans, collisions, emergency teleports,
      visible spawns/despawns, decision time, pathfinding time, and active agents
      by tier.
- [ ] Create one deterministic `living_city_gauntlet` scene or script with a
      sidewalk, four-way junction, crossing, POIs, parked cars, and an obstacle.
- [ ] Capture the current baseline for 20 minutes at the medium quality preset.
- [ ] Add runtime probes for route completion, red-light compliance, pedestrian
      crossing safety, panic recovery, and invisible streaming.
- [ ] Record CPU/GPU/frame-time results in `docs/profiles/`.

**Exit gate:** every bad behavior can be named from a debug state or counter,
and the same scenario can reproduce it in CI or a deterministic capture.

## LC1 - Build the semantic mobility graph

**Goal:** replace the shared "walkability grid for everything" with legal,
typed routes for each kind of agent.

- [ ] Extend `RoadNetwork` from two-way centerlines to directed lanes with lane
      width, speed limit, allowed vehicle classes, and stable segment IDs.
- [ ] Generate explicit turn connections at junctions; reject impossible
      U-turns and turns that cross non-driveable space.
- [ ] Add junction metadata: stop lines, signal group, conflict zone, priority,
      and blocked-box detection.
- [ ] Build a pedestrian graph from sidewalks/paths with curb portals, marked
      crossings, stairs, and POI entrances.
- [ ] Connect pedestrian crossings to traffic junction state so both systems
      agree on right of way.
- [ ] Add graph validation: disconnected components, zero-length edges, unsafe
      crossing links, duplicate IDs, and dead-end lanes without a legal exit.
- [ ] Publish graph chunks per world tile and reconnect borders on stream-in.

**Exit gate:** a route probe can request legal car and pedestrian routes across
the gauntlet and at least two adjacent world tiles without using a generic
walkability-grid shortcut.

## LC2 - Unify the agent runtime and simulation LOD

**Goal:** one understandable lifecycle for citizens and drivers.

- [ ] Introduce stable agent records containing identity, traits, current
      intent, route progress, home district, vehicle link, and short memory.
- [ ] Split immediate reflexes from slower deliberation so panic/avoidance never
      waits for a schedule tick, while schedules do not run every physics frame.
- [ ] Add explicit state-transition priorities: dead/incapacitated, immediate
      danger, collision avoidance, incident duty, urgent need, schedule, idle.
- [ ] Add deterministic per-agent RNG seeds; reloading or tier changes must not
      randomly replace personality and destination.
- [ ] Implement Tier A/B/C promotion and demotion with hysteresis.
- [ ] Pool scene agents and animation rigs; never free and recreate identities
      merely because the player turned around.
- [ ] Make `CrowdDirector`, `CityDirector`, and traffic use the same population
      registry and spatial-query service.

**Exit gate:** one named citizen and one named driver can leave view, become
virtual, progress along their trip, return, and retain identity and intent.

## LC3 - Make pedestrians move like people

**Goal:** believable navigation is solid before deeper life simulation.

- [ ] Route every live citizen through the pedestrian graph; straight-line
      wander is only an explicit open-area activity.
- [ ] Wire `NpcSteering` separation/arrival into `Citizen` locomotion using
      spatially queried neighbors instead of scanning every citizen.
- [ ] Add reciprocal local avoidance, personal-space preferences, overtaking,
      and small side bias so opposing flows pass instead of deadlocking.
- [ ] Add blocked-path detection, short local detours, timed replan, and a final
      recovery path that never teleports while visible.
- [ ] Add curb waiting and crossing groups; pedestrians cross only at legal
      links and only when `PedestrianTraffic.safe_to_cross` and the signal allow.
- [ ] Wire car-threat prediction and lateral dodge for a vehicle that violates
      the crossing.
- [ ] Add destination slots for standing, sitting, queueing, working, and
      socializing so agents do not stack on one POI coordinate.
- [ ] Blend locomotion animation for start, stop, turn, walk, jog, stairs, idle,
      and panic without foot sliding or instant 180-degree snaps.

**Exit gate:** 40 pedestrians run for 20 minutes in the gauntlet with no wall
crossing, no unresolved deadlock over 5 seconds, no visible teleport, and at
least 99% of assigned trips completing or explicitly replanning.

## LC4 - Make traffic obey and adapt

**Goal:** cars form plausible traffic rather than moving decoration.

- [ ] Route `TrafficDirector` exclusively over the lane graph and remove the
      straight-line fallback from production scenes.
- [ ] Give each driver traits such as desired speed, patience, reaction time,
      braking comfort, lawfulness, and aggression.
- [ ] Use the existing IDM `TrafficModel` through a GDScript fallback/native
      optional boundary for smooth acceleration, following, and braking.
- [ ] Wire stop lines, `TrafficSignal`, `TrafficRules`, cross-traffic occupancy,
      and yellow-light dilemma-zone behavior.
- [ ] Add turn speed profiles and steering curves so cars remain in their lane
      through junctions.
- [ ] Add lane selection and limited lane changing for turns, slow leaders,
      stopped vehicles, and closures.
- [ ] Add horn, wait, reroute, and cautious obstacle bypass behaviors with
      cooldowns so one blockage does not produce permanent gridlock or noise.
- [ ] Add parking and trip endpoints: spawn from valid portals/parking, drive to
      a destination, park or exit through an off-screen portal.
- [ ] Give ambient vehicles coarse collision volumes and incident reporting;
      only player-critical vehicles need full `VehicleBody3D` simulation.

**Exit gate:** 30 cars run for 20 minutes through at least four connected
junctions with no overlap, no permanent blocked box, legal signal compliance,
smooth queues, and recovery after one lane is deliberately obstructed.

## LC5 - Turn schedules into visible daily life

**Goal:** citizens make purposeful trips and perform readable activities.

- [ ] Wire `Citizen`, `CityDirector`, `NpcSchedule`, `NpcNeeds`, and `NpcMind`
      into `miami.tscn`; the production crowd must no longer default to simple
      random `Pedestrian` behavior.
- [ ] Replace nearest-POI selection with capacity-aware choice by distance,
      opening hours, district, crowding, affordability, and need.
- [ ] Add multi-step trip plans: leave activity slot, walk/drive, cross, arrive,
      perform activity, then choose the next intent.
- [ ] Add activity durations and completion effects; needs are satisfied by
      actually performing an activity, not merely selecting its label.
- [ ] Support homes, jobs, food, leisure, shopping, services, parks, and
      nightlife with data-driven schedule templates.
- [ ] Vary population mix and trip demand by hour, district, weekday profile,
      weather, and nearby events.
- [ ] Let some citizens own/use a vehicle while others walk; preserve the
      citizen-driver-vehicle relationship across simulation tiers.
- [ ] Add graceful fallback when a POI closes, fills up, streams out, or becomes
      unsafe.

**Exit gate:** a compressed full day visibly produces morning travel, work and
lunch peaks, evening leisure, and night thinning. A sampled citizen can explain
every destination with a schedule, need, or event reason.

## LC6 - Add social behavior and environmental use

**Goal:** NPCs do more than travel between coordinates.

- [ ] Add reusable activity-slot scenes/markers for benches, counters, queues,
      storefront browsing, vending, smoking, phones, conversations, and work.
- [ ] Add pair/group formation with consent, compatible intent, spacing, turn
      taking, and clean breakup when either participant leaves or panics.
- [ ] Add contextual ambient actions based on place, weather, time, traits, and
      nearby objects.
- [ ] Rate-limit barks by area and context; conversations must not become a wall
      of simultaneous text/audio.
- [ ] Add lightweight transactions and queues at service POIs so crowds react
      to capacity instead of occupying the same point.
- [ ] Add small ambient events that temporarily recruit nearby suitable NPCs,
      then return them to their previous plans.

**Exit gate:** a five-minute hands-off street observation shows at least six
distinct readable activities, two social interactions, and agents entering and
leaving them without stacking or getting stuck.

## LC7 - Connect perception, reactions, and consequences

**Goal:** the city notices events, reacts proportionally, and recovers.

- [ ] Add a local incident coordinator for sound, sight, collision, crime, fire,
      injury, obstruction, and emergency events.
- [ ] Wire `SoundPropagation`, line of sight, facing, weather visibility, and
      attention into one per-agent perception result.
- [ ] Expand the reaction ladder: orient, pause, avoid, complain/honk, gawk,
      record, flee, seek cover, help, call services, or confront.
- [ ] Use traits, relationship, role, current activity, danger, and memory to
      choose reactions; not every witness should make the same decision.
- [ ] Wire `CrimeWitness` report progress into wanted heat and allow reports to
      be interrupted plausibly.
- [ ] Wire `CrowdPanic` through spatial neighbors and safe flee destinations;
      fleeing agents must avoid running into traffic or dead ends.
- [ ] Make drivers brake, swerve, honk, reverse, abandon a blocked route, or
      flee an incident according to available space and driver traits.
- [ ] Dispatch police, ambulance, or fire response from valid road portals and
      give bystanders room for responders.
- [ ] Add recovery: calm down, inspect damage, resume the interrupted plan,
      choose a safer destination, or remember and avoid the area temporarily.

**Exit gate:** deterministic gunshot, crash, blocked-road, fire, and reckless
driving scenarios produce different but explainable reactions, witness reports,
traffic disruption, emergency access, and eventual return to normal flow.

## LC8 - Preserve continuity off screen

**Goal:** the city keeps moving without simulating every body at full fidelity.

- [ ] Run schedules, trips, needs, vehicle ownership, and major incidents in the
      Tier C virtual population.
- [ ] Persist important identities and recent memories within the session; hook
      into M5 save/load only through a narrow serializable agent-record API.
- [ ] Reconstruct returning agents at legal route positions, entrances,
      parking spaces, or activity slots outside the camera frustum.
- [ ] Track district-level population, trip demand, traffic load, closures, and
      emergency demand so streaming a tile reflects what happened off screen.
- [ ] Add continuity tests for leaving/re-entering a district, time skips,
      save/load, and floating-origin shifts.

**Exit gate:** the player can leave a busy block, spend an in-game hour
elsewhere, and return to a changed but coherent population without obvious
reset, duplication, or visible spawning.

## LC9 - Density, animation polish, and performance lockdown

**Goal:** reach the final density and presentation without breaking the frame
budget.

- [ ] Profile the complete living-city stack before moving more work to C++.
- [ ] Keep combined physics + traffic + crowds within the architecture budget
      of 3 ms at 1080p on the reference mid-range GPU/CPU.
- [ ] Initial medium-preset target: at least 40 visible/resident pedestrians and
      20 visible/resident ambient cars, with additional Tier C district agents.
      Raise density only when measured frame time and visual readability allow.
- [ ] Batch perception and spatial queries; prohibit per-agent full-tree scans.
- [ ] Time-slice route requests and deliberation; cap work per frame and expose
      deferred-job counters in the debug HUD.
- [ ] Add animation/render LOD, rig update throttling, pooled props, and
      impostors where profiling shows a benefit.
- [ ] If profiles prove a GDScript bottleneck, move only the narrow stable core
      to `engine/` and keep a GDScript fallback.
- [ ] Capture day, night, rain, rush-hour, panic, and gridlock-recovery profiles
      plus a 20-minute soak test.

**Exit gate:** the living-city gauntlet and playable Miami district hold 60 FPS
at the medium preset, pass all behavior probes, and complete the soak without
agent leaks, escalating path queues, or unrecovered deadlocks.

## Delivery order

Do not implement all pedestrian systems and then all traffic systems. Ship
vertical slices in this order:

1. Debug overlay, counters, and deterministic gauntlet.
2. One semantic city block with sidewalks, crossings, lanes, junctions, and POIs.
3. Ten citizens completing legal trips through that block.
4. Ten cars obeying the same block's junction and crossing semantics.
5. Pedestrian-car avoidance and one recoverable blockage.
6. A compressed daily cycle with activities and parking.
7. One incident from perception through reactions, witness reporting, response,
   and recovery.
8. Tiered streaming and continuity across two tiles.
9. Scale density only after the complete loop is profiled.

Each slice must be playable, have pure unit tests for new decision logic, add
or extend a runtime probe, and pass `tools/check.sh`.

## Final acceptance scenarios

The M4 roadmap boxes are ready to close only when all scenarios pass:

| Scenario | Required result |
| --- | --- |
| Morning commute | Citizens leave valid origins, choose walk/car, obey routes, reach capacity-aware destinations |
| Busy crossing | Pedestrians wait, cross in groups, and dodge a violating car; traffic yields and resumes |
| Obstructed lane | Traffic queues without overlap, selected drivers reroute or bypass, and the junction clears |
| Minor crash | Nearby agents notice at different thresholds; drivers brake/honk; some bystanders gawk or call |
| Gunshot | Hearing/LOS differ, panic propagates locally, witnesses report, agents flee to safe routes, then recover |
| Weather change | Visibility, walking choices, traffic speed/grip, and ambient activity respond without global instant state flips |
| Leave and return | Agent identities and district conditions progress off screen and reconstruct invisibly |
| Soak | Twenty minutes at target density with no visible spawning, leaks, permanent deadlock, or budget regression |

These scenarios define "living city" more usefully than a raw feature count.
