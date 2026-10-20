# NAT and Endpoints

Everything in this chapter follows
from two facts: only the side that
starts a conversation needs to know
where the other side is, and the
middleboxes between them forget idle
UDP. Endpoints, keepalives, roaming,
and port forwards are those two facts
wearing different coats.

## Who needs an Endpoint

The **initiator** needs one: an
`Endpoint` line naming where its peer
can currently be reached. The
**responder** needs none, and the
lab's hub has none — when the spoke's
first authenticated packet arrives,
the hub learns the spoke's endpoint
from that packet's return address and
writes it into its state (watch it
appear in `wg show` as the `endpoint`
line, chapter 7). Replies and later
initiations from the hub use the
learned address until fresher news
arrives.

This asymmetry is what makes hub and
spoke (chapter 8) the natural shape:
the machine that doesn't move is the
one that must be findable; everything
else can hide behind whatever NAT it
woke up behind today.

## Why keepalive exists

NAT — the thing that lets a household
share one public address — keeps a
temporary **mapping** for each UDP
conversation: "packets from the café
laptop's port go out wearing this
public port; send replies there." Idle
mappings expire, on a timer the NAT
chooses and doesn't publish — tens of
seconds to a few minutes on consumer
gear. While the mapping lives, the
hub can reach *in* to the spoke.
After it dies, the spoke is
receive-only-by-initiation: it can
still start (its first packet mints a
fresh mapping), but nothing can wake
it until it does.

**`PersistentKeepalive = 25`** —
seconds between empty packets the
*spoke* sends purely to keep the
mapping warm. Twenty-five is the
conventional value: under common
mapping lifetimes, frequent enough to
matter, rare enough to cost almost
nothing (an empty handshake-sized
heartbeat every 25 seconds). Rules of
thumb:

- Set it on the side behind NAT —
  the spoke. The hub needs none; its
  replies ride mappings the spoke's
  traffic refreshes.
- It is off by default and off is
  right for machines with public
  addresses or spokes that only ever
  initiate.
- You can change it on a live peer —
  captured on the lab, `wg set`
  adding it and the new line appearing
  in `wg show`:

```
  persistent keepalive: every 25 seconds
```

That live-set line is also the rescue
for the classic symptom: *the tunnel
works when I connect out, but home
can't reach the laptop after it's
been idle a few minutes.* That's not
a WireGuard fault; it's a forgotten
mapping, and keepalive is the fix.

## Endpoint drift, both directions

**The spoke moves** — new café, DHCP
renewal, phone hopping to cellular.
Healed automatically: the hub relearns
the endpoint from the spoke's next
authenticated packet, whenever it
arrives. No config changes anywhere.
This is the roaming behaviour, and
it's silent about one thing: while
the spoke is between addresses, the
hub's endpoint line is *stale news*,
not an error.

**The hub moves** — its public address
changes (ISP renumbering, a router
swap). Not healed: the spoke's
`Endpoint` is a static line in a file,
and it will aim at the old address
forever. Symptoms are the mirror of
the NAT one: a tunnel that worked
yesterday and handshakes with nobody
today, with the spoke's config
untouched — because the fact that
changed isn't in the config. Fixes:

- **Name, don't number.** An endpoint
  may be a DNS name; wg-quick resolves
  it at bring-up. Dynamic-DNS for the
  hub plus a named endpoint turns an
  address change into a non-event at
  the next `up`. Mid-session, the name
  is *not* re-resolved on its own —
  the tools ship a helper for that
  (`reresolve-dns.sh` in wg-quick's
  examples, meant to be run from a
  timer) — described, as the build
  machine has no live tunnel to heal.
- **Re-set the endpoint live.**
  `wg set wg0 peer <key> endpoint
  new.address:51820` takes effect
  immediately, no restart — the same
  live-edit family as the keepalive
  above.

## The hub must be reachable

One side needs a real inbound path:

- **Port forwarding.** A hub behind a
  home router needs that router to
  forward its ListenPort (UDP 51820
  by default) to it. Forward the port
  you configured, UDP only.
- **Choosing a port people let
  through.** 51820 is the convention,
  but nothing binds you to it; some
  hostile networks pass only common
  ports, and UDP 443 — QUIC's home —
  is a popular choice for a hub for
  exactly that reason. The port is a
  ListenPort line on the hub and a
  number in every spoke's endpoint;
  nowhere else.
- **Carrier-grade NAT is a wall, not
  a hurdle.** If the hub's "public"
  address is itself behind the ISP's
  NAT (common on cellular and some
  fibre), no forwarding exists to
  configure — inbound is impossible
  there. Move the hub role to a
  machine with a real address (a
  small VPS is the usual answer), or
  accept the other side initiating —
  the shapes in chapter 8 are how
  you choose.

Check: from outside, the hub's UDP
port should be silent to a scan
(chapter 1: silence is correct — you
confirm reachability with a real
handshake from a real spoke, not a
probe), and a spoke left idle longer
than a NAT mapping's life should
still be reachable from the hub if —
and only if — its keepalive line is
set.
