# AllowedIPs and Routing

If one line in a WireGuard config earns
a whole chapter, it's `AllowedIPs`. It
looks like an access-control list. It
is — and it's also the routing table.
One list, two jobs, and nearly every
"WireGuard is connected but nothing
works" story ever told is one of the
two jobs being misunderstood.

## Job one: the way out

When a packet enters the tunnel, the
kernel asks: *which peer is this for?*
It consults every peer's AllowedIPs as
one routing table, longest match first
— the same rule ordinary routing uses.

- Outbound to `10.99.0.1`, and one peer
  lists `10.99.0.1/32`: that peer.
- One peer lists `10.99.0.0/24`, another
  lists `10.99.0.2/32`: traffic to
  `10.99.0.2` takes the /32 (longer
  match), everything else in the /24
  takes the first peer. Overlapping
  lists are legal and useful — a hub
  carrying the whole subnet, plus one
  direct peer carved out.
- A peer listing `0.0.0.0/0` matches
  *everything*: that peer is the
  tunnel's exit to the world (chapter
  9).
- An address no peer lists goes
  nowhere — it never enters the tunnel
  at all. "The tunnel is up but I can't
  reach X" usually means X's address
  isn't in anyone's AllowedIPs, here
  or as a route (with bare `wg`, routes
  are yours to add; `wg-quick` adds
  them from AllowedIPs for you).

## Job two: the way in, checked

When a packet arrives and is decrypted,
WireGuard knows which peer sent it —
the keys prove that. Then it checks the
packet's *source address* against that
peer's AllowedIPs. Not in the list? The
packet is dropped, silently, after
decryption. This is the anti-spoofing
binding: a peer can only ever *be* the
addresses in its list, so a compromised
or misconfigured machine cannot claim
another machine's tunnel address, and
traffic for `10.99.0.2` will only ever
be accepted from the holder of the key
whose list contains `10.99.0.2`.

The two jobs together are what the
WireGuard design calls **cryptokey
routing**: the table that routes is the
table that authenticates.

## One address, one owner — enforced by theft

What happens if two peers claim the
same address? Not an error. Captured
live on the lab, adding a third peer
claiming the spoke's `10.99.0.2/32`:

```
$ wg set wg-hub peer 4N4csAWVpLEScMKf7yRK018lg2ocLh88hywGDr/X0C0= allowed-ips 10.99.0.2/32   (already claimed by the spoke peer — what happens?)
$ wg show wg-hub allowed-ips
rl3NB9ayaoVXhB6XhivPev+vFeB7MWIRXHS6D9+Ocnk=	(none)
4N4csAWVpLEScMKf7yRK018lg2ocLh88hywGDr/X0C0=	10.99.0.2/32
```

Read that carefully. The command
succeeded (exit 0, no warning). The
address **moved**: the new peer owns
`10.99.0.2/32` now, and the spoke's
entry reads `(none)` — it kept its key,
its preshared secret, its place in the
config, and lost its entire claim to
send or receive. And removing the
thief does **not** give the address
back; the repair is to restore the
configuration (`wg setconf` with the
real config — captured in the
transcripts kept with this guide — or
re-adding the AllowedIPs to the right
peer).

This is the single most dangerous
property in everyday WireGuard
administration, precisely because it
is silent and successful. The habits
it dictates:

- One tunnel address, exactly one
  owner, everywhere. Keep a list of
  who owns what next to the hub's
  config; the hub's config *is* that
  list, so keep it right.
- After adding any peer, on any
  machine, run `wg show <iface>
  allowed-ips` and confirm no existing
  peer went to `(none)`.
- A tunnel that dies the moment you
  add a new peer was not attacked and
  did not crash. Its address was
  stolen by your own edit.

## The one-way tunnel

The mirror-image mistake: handshakes
succeed, the hub receives the spoke's
packets fine, replies never arrive.
Route out worked (job one, on the
hub: the spoke's address is in its
peer list) — but check job two on the
*spoke*: if the hub's address isn't in
the spoke's AllowedIPs for the hub
peer, the spoke drops every reply
after decrypting it, on the floor,
silently. Both machines' lists must
mirror: each side's AllowedIPs must
contain the address the other side
will actually use as its source.

Check: on each machine, `wg show
<iface> allowed-ips` shows exactly the
addresses you assigned, one owner
each, no `(none)` where an address
should be, and each peer's list
contains the address you'll ping.
