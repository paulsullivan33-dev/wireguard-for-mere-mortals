# WireGuard for Mere Mortals

**WireGuard** is a way for two machines
that hold each other's keys to talk as if
a private wire ran between them — over
ordinary internet connections, encrypted
end to end. It is a protocol, not a
service: no account, no company in the
middle, no directory of your machines.
You make the keys, you write the
configs, you decide who is a peer. This
guide teaches exactly that — the raw
protocol and its two small tools, `wg`
and `wg-quick` — for a smart beginner
administering machines of their own.

If you already know this series'
*Tailscale* guide: that one drives the
car Tailscale built. This one opens the
bonnet on the engine — the same
WireGuard, with you doing by hand the
three jobs Tailscale automates: keys,
peers, and address lists.

A note on how this guide was verified.
wireguard-tools was installed fresh on
the build machine, and the laboratory —
two interfaces, `wg-hub` and `wg-spoke`,
on one machine — was really built: keys
generated, configs loaded, interfaces
brought up, peers changed live, an
AllowedIPs address really stolen by a
test peer and really restored. But the
build machine lives in a sandbox with
no WireGuard kernel module that also
refuses to send UDP at the OS level —
so no handshake can complete there, and
the guide doesn't pretend otherwise.
Handshakes are taught from the captures
that sandbox *does* produce (interfaces
up, state perfect, the userspace
daemon's log retrying its initiations
every five seconds against the OS's
refusal) plus prose descriptions of
the success state, labelled as
described wherever the distinction
matters. `criteria.md` keeps the full
ledger.

## What this guide covers

- [**What WireGuard is**](what-wireguard-is.md) —
  a protocol, not a service; the three
  ideas; silent by design; what it
  can't do
- [**Keys**](keys.md) — making a pair,
  the preshared key, and why you can't
  tell a private key by looking
- [**Your first tunnel**](your-first-tunnel.md) —
  the two-machine lab on one machine,
  built by hand: configs, `setconf`,
  addresses, and the before picture
- [**Reading the config**](reading-the-config.md) —
  every field in both sections, whose
  dialect each line speaks, and reading
  a config as a sentence
- [**wg-quick**](wg-quick.md) — the
  front end: `strip`, the narrated
  bring-up (including its userspace
  fallback), down, and the service
- [**AllowedIPs and routing**](allowedips-and-routing.md) —
  the list that routes *and*
  authenticates, longest match, spoof
  checks, and the silent theft of an
  address, captured live
- [**Reading `wg show`**](reading-wg-show.md) —
  handshakes, endpoints, transfer
  counters, and the dump that prints
  private keys
- [**Topologies**](topologies.md) —
  point-to-point, hub and spoke, site
  to site, mesh, and planning the
  tunnel subnet
- [**Full tunnel, split tunnel**](full-tunnel-split-tunnel.md) —
  the one AllowedIPs line that decides,
  what each shape costs, and choosing
- [**DNS leaks and the kill switch**](dns-leaks-and-kill-switch.md) —
  the leak nearly everyone has, the
  `DNS =` line, and a kill switch
  assembled honestly from parts
- [**NAT and endpoints**](nat-and-endpoints.md) —
  who needs an endpoint, why
  keepalive exists, drift in both
  directions, and being reachable
- [**MTU**](mtu.md) — the 60-byte
  wrapper, why 1420, and the
  small-passes-big-hangs black hole
- [**Key hygiene**](key-hygiene.md) —
  one pair per machine, revocation by
  deletion, rotation as a procedure,
  and the leak response
- [**Troubleshooting**](troubleshooting.md) —
  no-handshake in four ordered causes,
  one-way tunnels, the stolen address,
  idle death, and the clock that isn't
  a suspect
- [**Glossary**](glossary.md) — the
  terms, collected in one place

## What it doesn't cover

WireGuard as a commercial VPN service
(there isn't one — picking a provider
that uses WireGuard is a different
shopping trip); the mobile and desktop
apps beyond noting they read the same
configs (this guide's hands are Linux
hands, and it says so); enterprise
fleets and their automation — the
subject the Tailscale guide exists
for; the cryptography's internals
beyond what operating it requires;
and IPv6 tunnels beyond the wrapper
arithmetic and the `::/0` line — the
lab is IPv4, and the guide doesn't
fake a second lab.

## How to use this guide

Read chapters 1–3 with a machine in
front of you — a spare box, a VM, a
$5 cloud instance all count — and
build the lab as you go:
`sudo examples/lab.sh up` stands up
the same two interfaces the chapters
use. Keep the lab afterwards: a pair
of interfaces whose state you *know*
is the standing rehearsal for the day
a real tunnel's silence needs reading.
