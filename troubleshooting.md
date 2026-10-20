# Troubleshooting

Every symptom below was either
reproduced on the build machine while
this guide was written, or follows
directly from a capture in an earlier
chapter. The method is chapter 7's:
compare the file you wrote, the config
the machine holds (`wg showconf`), and
the state the traffic produced
(`wg show`). WireGuard's silence means
you always diagnose from your own
side — but your own side, read
properly, says a great deal.

## No handshake, ever

The master symptom: `latest handshake`
never appears. Work it in this order —
each step is cheaper than the next is
clever:

1. **Is the peer even there?** `wg show`
   lists no peer, or the wrong one: the
   config never loaded, or loaded onto
   a different interface than the one
   you brought up. `wg showconf` is the
   machine's own testimony.
2. **Do the keys mirror?** Your peer's
   `PublicKey` must be the public half
   of the private key the other machine
   actually holds, and vice versa. A
   wrong key — one character off from
   a sloppy paste — produces *total,
   silent* failure on both ends: the
   hub drops the initiations as coming
   from a stranger, and by design says
   nothing. A mismatched **preshared
   key** is the identical picture with
   correct key pairs. Compare both
   machines' `wg show` public keys
   against the configs, character by
   character; this is the cause often
   enough that it earns step two.
3. **Is UDP getting there at all?**
   WireGuard's first packet is a UDP
   datagram to the endpoint. Any wall
   that eats UDP — a firewall on either
   end, an egress policy, a router that
   was never told to forward the port —
   leaves the initiator retrying
   forever. The build machine is the
   limiting case, captured with the
   daemon's own log (a `wireguard-go`
   run at debug level; the kernel
   implementation is quieter, the
   retries identical):

   ```
   DEBUG: peer(EJPF…K9Cs) - Sending handshake initiation
   ERROR: peer(EJPF…K9Cs) - Failed to send handshake initiation: operation not permitted
   ```

   …every five seconds, which is
   WireGuard's handshake retry
   interval, visible in the timestamps.
   On that machine a two-line probe
   proved the wall was the OS, not
   WireGuard — UDP `sendto` refused
   outright, TCP fine:

   ```
   UDP sendto: [Errno 1] Operation not permitted
   TCP connect: OK
   ```

   Your version of the probe is
   simpler: from the spoke's network,
   can *anything* reach the hub's UDP
   port? Another spoke that works is
   the best witness. And confirm the
   hub's router actually forwards the
   ListenPort you configured — the
   mismatch of "forwarded 51820,
   configured 51821" has ended more
   evenings than any cryptography.
4. **Is the endpoint still true?**
   Yesterday's hub address, faithfully
   configured. Chapter 11: hub-side
   moves aren't healed. If the hub's
   public address changed, the spoke
   aims at a stranger's silence,
   which looks exactly like every
   other silence in this section.

## The interface is up and nothing flows

`ip link` says UP, `wg show` shows
peers — and no traffic. Recall chapter
3's before picture: that is what a
freshly configured tunnel looks like
*before its first packet*, and if no
handshake has ever completed it is
simply still in that state. Interface
up is a statement about your machine.
The tunnel is a statement about two.

## Handshake works, traffic flows one way

Replies die after decrypting on the
receiving side: the receiver's
AllowedIPs for the sender don't
include the address the sender is
sending *from*. Chapter 6's job two.
`transfer` tells the story — one
side's *sent* climbs while its
*received* sits still.

## It worked until I added a new peer

Chapter 6's theft, returning as a
symptom: the new peer's AllowedIPs
claimed an address an existing peer
owned, and the address moved —
silently, successfully, exit code 0.
`wg show <iface> allowed-ips` shows
the victim at `(none)`. Restore the
victim's AllowedIPs (or `wg setconf`
the whole known-good config) and keep
the registry discipline from chapter
13.

## Works, then stops after some idle minutes

The spoke fell off the hub's reach
when its NAT mapping expired. Finding:
everything works when the spoke has
just spoken; after quiet, the hub
can't initiate in. `PersistentKeepalive`
(chapter 11) — and confirm it's set on
the *spoke's* peer entry, where it
belongs, not the hub's.

## Worked yesterday, dead today, nothing changed

Something did change; it just wasn't
your config. In rough order: the hub
rebooted and the tunnel didn't come
back (was `wg-quick@` enabled, or did
you bring it up by hand in a session
that's gone? — `ip link show wg0` on
the hub answers in one line), the
hub's public address changed (above),
the spoke is on a new network whose
egress blocks your UDP port (try the
tunnel from a different network
before rebuilding anything), or the
hub machine's own firewall learned a
new default in an update.

## Small things pass, big things hang

Not a WireGuard fault at all: an MTU
black hole on the path. Chapter 12
has the signature and the sweep.

## "Is it my clock?"

The suspect that isn't one. WireGuard
has no certificates and nothing in it
expires, so ordinary clock skew —
minutes, hours — cannot break a
tunnel, and has never been the cause
of any symptom in this chapter. (The
handshake does carry an internal
timestamp, used only to refuse
*replayed* initiations; it takes a
clock leaping backwards past a
previous handshake to even touch it,
which is a curiosity, not a
checklist item.) If your clocks are
wrong, fix them for the logs' sake —
diagnosing anything is harder with
lying timestamps — but look for the
tunnel's problem in the sections
above.
