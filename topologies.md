# Topologies

WireGuard has no server and no client —
only peers — but arrangements of peers
fall into a few shapes, and the shape
decides who holds which configs, who
forwards packets, and what breaks when
a machine moves. Pick the shape before
writing configs; most home networks
want the second one.

## Point to point

Two machines, one `[Peer]` block each,
each listing the other's single tunnel
address. The lab is this shape. Use it
for exactly what it says: a wire
between two machines — a backup path, a
private link between a workstation and
one server. Nothing forwards anything;
each side's AllowedIPs is one `/32`.

## Hub and spoke

One machine with a stable address holds
a `[Peer]` block per spoke; each spoke
holds exactly one block, for the hub.
The hub is the only side that must be
reachable — spokes can sit behind NAT,
move, and renumber, and the hub learns
their endpoints as they check in
(chapter 11). Adding a machine touches
two files: the new spoke's, and the
hub's (one new block). This asymmetry
is the shape's whole virtue: the config
that grows lives on the machine that
doesn't move.

Variations that matter:

- **Spoke reaching the hub only** —
  the lab's shape. Spoke's AllowedIPs
  for the hub: the hub's `/32`.
- **Spokes reaching each other** —
  each spoke widens its hub entry to
  the whole tunnel subnet (`10.99.0.0/24`)
  and the hub *forwards*: with IP
  forwarding enabled on the hub
  (`net.ipv4.ip_forward=1`), packets
  arriving from one spoke leave toward
  another. The hub's own AllowedIPs
  don't change — each spoke is still
  one `/32` there; forwarding is a
  property of the hub's routing, not
  of WireGuard.
- **Spokes reaching the hub's LAN** —
  the spoke adds the LAN subnet (say
  `192.168.1.0/24`) to its hub entry's
  AllowedIPs, the hub forwards, and
  one more piece must agree: the LAN
  must know the way back. Either the
  hub NATs tunnel traffic into the LAN
  (a masquerade rule — the LAN sees
  the hub's address and replies to it),
  or the LAN's router gets a route for
  the tunnel subnet via the hub. One
  of the two, or replies die on the
  LAN — chapter 14's most ordinary
  ghost.

*(Forwarding and NAT are described
here, not captured: the build
machine's sandbox can't run them. The
commands are the standard ones —
`sysctl net.ipv4.ip_forward=1` and an
`iptables`/`nft` masquerade on the
hub's LAN interface — and each guide
machine's own firewall tooling is
where they belong.)*

## Site to site

Two hubs, each with a stable address,
each holding the other as a peer whose
AllowedIPs covers the *other site's
whole LAN*, both forwarding. Machines
on either LAN use their own router's
route to the tunnel subnet and never
run WireGuard themselves. This is hub
and spoke with both ends anchored —
the shape for joining a home and an
office. The new failure mode is
address planning: the two LANs must
not overlap, and neither may collide
with the tunnel subnet.

## Full mesh

Every machine peers with every other:
N machines, N−1 blocks each, changes
everywhere when a machine joins. It
wins when machines must talk directly
without a hub's bandwidth or
availability in the path, and there
are few of them. It loses on key
administration exactly as fast as N
grows — the chore that chapter 8 of
the *Tailscale* guide describes
automating away. For a handful of
servers it's honest work; for a
household, hub and spoke is the
answer nine times in ten.

## Choosing the addresses

Whatever the shape, plan the tunnel
subnet once:

| Decision | Guidance |
|---|---|
| Which subnet | A quiet corner of private space your LANs don't use — the lab's `10.99.0.0/24` is a fine pattern. Avoid `192.168.0.0/24` and `192.168.1.0/24`: half the world's routers live there, and a travelling spoke *will* land on a LAN that collides with your tunnel. |
| Who gets what | One address per machine, written down in the hub's config — the hub's peer list is the registry. |
| Hub-side entries | `/32` per spoke, always. Subnets belong in *spoke*-side entries (toward the hub) and site-to-site entries, not in the hub's per-spoke lists. |
| Room to grow | A /24 is 254 machines. Households don't outgrow it; if you might, take a /16 of quiet 10-space now and save a renumber later. |

Check: before writing any config, you
can say the shape in one sentence,
name the machine(s) that forward, and
point at the list that says who owns
which tunnel address. If any of the
three is fuzzy, the configs will be
too.
