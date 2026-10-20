# DNS Leaks and the Kill Switch

Two topics share this chapter because
they are the same worry at two sizes:
traffic you believed was in the tunnel,
walking outside it. DNS is the leak
nearly everyone has; the kill switch
is the answer for people who can't
tolerate any leak at all.

## The DNS leak

A full tunnel (chapter 9) routes your
packets through home. But *which
packets* did you picture? Browsers ask
for names before they connect to
addresses, and name lookups — DNS —
are their own traffic. If the tunnel
moves your web traffic but your DNS
queries still go to the resolver of
whatever network you're sitting on,
three things leak:

- **The questions themselves.** The
  local resolver (and anyone watching
  it) sees every name you look up —
  a reading list of your browsing,
  in the clear, even though the
  browsing itself went home encrypted.
- **The answers' provenance.** Home
  machine names — the NAS, the printer
  admin page — exist only in home's
  resolver. Ask the café's resolver
  and they don't exist; ask it about
  public names and you get *its*
  answers, including any filtering or
  rewriting it does.
- **Split-tunnel surprises.** In a
  split tunnel the inverse bites: a
  home name resolves fine (you asked
  the right resolver by habit) — no,
  it resolves *nowhere*, because your
  laptop is still asking the local
  resolver, which has never heard of
  your house.

## The DNS line

wg-quick configs carry the fix as the
`DNS =` line from chapter 4 (the lab's
spoke points it at the hub,
`DNS = 10.99.0.1`). While the tunnel
is up, wg-quick points the system's
resolver at the named server — through
whatever resolver machinery the system
uses — and on `down` it puts things
back. The line only does anything
because the resolver it names is
*reachable through the tunnel*, which
is why it names a tunnel address.

*(Described, not captured: chapter 5's
`strip` capture shows the line being
consumed by wg-quick, but the build
machine's sandbox runs no resolver
integration to switch, so the switch
itself wasn't exercised here. The
behaviour above is wg-quick's
documented behaviour.)*

Two honest limits:

- **It's all-or-nothing per tunnel.**
  wg-quick's DNS setting applies to
  the whole system while the tunnel
  is up: in split mode, *every*
  lookup takes the trip home, not
  just home names. Usually fine —
  home's resolver answers public
  names too — but know that you
  chose it. Per-domain routing of
  DNS ("home names to home, the
  rest local") is a job for a
  resolver that understands links,
  like systemd-resolved with the
  tunnel as a DNS link; WireGuard
  itself has no opinion about names
  at all.
- **The hub must actually run a
  resolver for you** — many routers
  and NAS boxes do; a bare hub
  machine needs one installed
  (dnsmasq, unbound, or the router
  upstream). `DNS = 10.99.0.1` with
  nothing listening on the hub is a
  tunnel where nothing resolves,
  which is at least a loud failure.

## The kill switch

Suppose the tunnel *drops* — the hub
reboots, the café Wi-Fi flaps, you
close the laptop mid-yawn. Where does
your traffic go? Without a kill
switch: out the local connection, in
the clear, the moment routes fall
back. Programs don't announce this.
The tunnel icon just quietly becomes
a lie you believed a second ago.

WireGuard has no kill-switch feature.
The protocol's job is the wire; what
you assemble is a posture, from two
parts:

1. **A full tunnel leaves nothing to
   fall back to cleanly.** With
   `AllowedIPs = 0.0.0.0/0` the only
   default route points *into* the
   interface. Tunnel dead mid-session
   means packets enter a black hole
   and fail — the safe direction to
   fail. The exposed window is the
   interface being *down* entirely
   (routes removed, local default
   restored), which is what part two
   is for.
2. **Firewall rules that refuse
   non-tunnel output.** The pattern
   the WireGuard documentation itself
   publishes: `PostUp` rules in the
   wg-quick config that, once the
   tunnel is up, drop outgoing traffic
   on the physical interface except
   the tunnel's own packets to its
   endpoint (and your LAN, if you
   allow it); `PreDown` removes them.
   With those in place, even
   `wg-quick down` leaves the machine
   mute rather than talkative.

*(Described from the official
documentation's example — the build
machine can neither forward nor
firewall a real uplink, so the rules
weren't run here. If you adopt them,
test on a machine you can walk to: a
kill switch that misfires at an
airport is indistinguishable from a
broken laptop, and the fix order —
tunnel down, rules off by hand —
should be practised, not theorised.)*

Check: with the tunnel up and DNS
set, a lookup of a name that exists
only at home resolves (and a "what is
my resolver" check names home's). If
you run a kill switch: with it armed,
bring the tunnel down and try to load
any page — it must fail. A kill switch
that has never been watched failing
is a hope, not a switch.
