# Full Tunnel, Split Tunnel

One AllowedIPs line decides the
personality of the whole tunnel: which
of your packets take the encrypted
path, and which walk out your local
connection as before. Nothing else
about the setup changes — same keys,
same handshake — only the breadth of
that one list.

## Split tunnel: the tunnel is a road somewhere

The spoke lists just the destinations
the tunnel is *for*:

```
AllowedIPs = 10.99.0.1/32
```

or, reaching the hub's whole world,
`AllowedIPs = 10.99.0.0/24,
192.168.1.0/24`. Everything else —
the web, updates, the coffee shop's
printer — uses your ordinary
connection, untouched. This is the
lab's shape and the right default for
"reach my home machines from away":

- **Fast.** No detour through home;
  your bulk traffic keeps its direct
  path and its usual speed.
- **Local things keep working.** The
  LAN you're sitting on — printers,
  the router's admin page, other
  people's machines you have no
  business tunnelling — behaves
  normally, because traffic to it
  never enters the tunnel.
- **The hub carries only tunnel
  traffic.** A small hub on a home
  uplink can serve many spokes this
  way.

The price is precision: the list must
name everything the tunnel is for,
and anything forgotten silently takes
the open path instead. "Silently" is
the operative word — chapter 10's DNS
leak is the famous case.

## Full tunnel: the tunnel is the road

The spoke lists everything:

```
AllowedIPs = 0.0.0.0/0, ::/0
```

Now every packet — web, mail, DNS,
updates — enters the tunnel and exits
wherever the hub sends it. This is the
classic "VPN mode": on hostile or
metered Wi-Fi, your traffic crosses
the room encrypted and emerges at
home, wearing the hub's public
address.

What it costs, stated plainly:

- **The hub becomes your ISP.** Its
  uplink is your speed ceiling, its
  bandwidth your bill, its address
  your public face — including its
  reputation and its logs.
- **The hub must forward and NAT.**
  A split tunnel to a hub that only
  *listens* works with no forwarding
  at all; a full tunnel asks the hub
  to route the internet for you
  (chapter 8's forwarding plus a
  masquerade). Get it wrong and the
  tunnel handshakes beautifully while
  the web simply doesn't load —
  chapter 14 again.
- **Local things break by default.**
  The printer on the café LAN is now
  "elsewhere," and elsewhere is
  through home. Reaching the local
  subnet requires carving it out —
  and WireGuard has no "except" —
  so carvers replace `0.0.0.0/0` with
  the complement: the long list of
  prefixes that means "everything
  except my LAN." People generate
  that list with calculator tools;
  it's roughly a hundred entries and
  it's legitimate, just ugly.

Under the hood of a full tunnel,
`wg-quick` does one more piece of
work worth knowing exists: it moves
your default route into a separate
routing table and marks the tunnel's
own encrypted packets so *they* keep
using the real connection — otherwise
the tunnel would try to carry its own
envelope and eat itself. It works,
and it's why full-tunnel problems
sometimes show routing tables that
look stranger than chapter 6 led you
to expect.

## Choosing

| Situation | Shape |
|---|---|
| Reach home services from a laptop that travels | Split |
| Untrusted Wi-Fi, and home has the uplink for it | Full |
| Joining two fixed networks | Subnets only (site-to-site, chapter 8) |
| A machine that should *only* ever talk through the hub | Full, plus chapter 10's kill switch |
| Unsure | Split — add destinations as they prove to belong in the tunnel |

The choice is per-spoke and costs one
line to change: the same hub can serve
a full-tunnel laptop and a split-tunnel
phone at once, because the list lives
on the spoke's side (the hub's per-peer
entries stay `/32` either way).

Check: pick a destination you believe
is in the tunnel and one you believe
isn't, and before connecting, say which
path each takes and which AllowedIPs
line decides it. Chapter 10 is about
the one destination everyone forgets
to decide on purpose: DNS.
