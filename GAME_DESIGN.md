# Game design

## Core loop

Two to four color-coded fighters compete on a compact rooftop above a miniature city. Movement, readable attacks, throwable props, and recoverable chaos support rounds that end when one fighter remains. Blue, red, yellow, and green identify setup slots. The default solo configuration adds a CPU opponent.

Menu → crew setup → countdown → fight → round result → next round → match champion. Three wins end the match; a total knockout awards zero points. A 0.6-second settlement window prevents the first fall in a near-simultaneous elimination from prematurely deciding the winner. Replay keeps the same crew and clears scores.

## Movement and combat tuning

The implementation favors direct control with momentum over realistic simulation. Fighters accelerate toward a requested velocity, retain reduced air control, and receive a separate decaying knockback velocity. Hits cause temporary stun; jumping and landing stretch/squash the procedural character.

| Value | Current default |
|---|---:|
| Run speed | 5.8 units/s |
| Acceleration | 24 units/s² |
| Air acceleration | 35% of ground acceleration |
| Jump speed | 8.5 units/s |
| Gravity | 22 units/s² |
| Carry/drag speed | 72% of normal |
| Punch range / cooldown | 1.65 units / 0.38 s |
| Shove range / cooldown | 2 units / 1.15 s |
| Punch / shove horizontal knockback | 6.5 / 12 units/s |
| Punch / shove stun | 0.3 / 0.65 s |
| Grab range | 1.8 units |
| Grab duration | Up to approximately 2.2 s |
| Elimination height | Below y = −8 |

Attacks use facing and distance checks, rather than animated hitboxes. Punch creates frequent short interruptions. Shove commits to a slower cooldown for greater displacement. A held fighter or prop changes shove into a throw. Grab selects the nearest eligible target in front; press grab again to release. Jump/punch struggles advance escape time, and hits interrupt holding.

## Arena and objects

The main roof is 14 × 10 units, framed by painted warning stripes. Three smaller roofs are separated by real gaps. Raised ventilation obstacles and six loose objects create opportunities to disrupt approaching fighters. Objects are box, cylinder, and sphere shapes standing in for crates, cans, and balls; their simple forms keep collision behavior readable.

Loose objects bounce and tumble as rigid bodies. A thrown prop can knock back an opponent during a 1.5-second danger window. It ignores its thrower and stops dealing attack impulses after its first fighter hit.

## Hazards

Every 20 seconds, the event manager randomly selects one hazard. Each has 2.5 seconds of warning followed by 5.5 seconds of activity.

| Hazard | Warning and effect |
|---|---|
| Wind | Text warning, then a random horizontal force on every fighter |
| Slippery roof | Rain/sliding text, then movement acceleration reduced to 13% |
| Collapsing side roof | Selected roof turns red and shakes, then its collision and visibility disappear |

Hazards reset on completion or a round transition. Collapse affects only a side roof and restores it afterward. Slipperiness changes fighter movement response and temporarily lowers prop friction. Wind warnings show the upcoming push direction using text arrows. Beyond 120 seconds, gradually stronger outward force pushes standoffs toward a physical result instead of assigning an arbitrary winner.

## Presentation and scope

Oversized heads, short arms, pastel fighters, dark roof surfaces, emissive paint, rooftop signage, and a fixed angled camera support readability. Native menus use navy, cream, and warm yellow. Impacts emit colored fragments, hit flashes, screen shake, and short procedural tones. Jump/landing and attack poses animate the character without a skeleton.

This MVP deliberately omits online networking, progression, customization, full ragdolls, external assets, and music. The next design decision should follow human playtests: tune edge recoverability, attack frequency, and grab escape before adding content.
