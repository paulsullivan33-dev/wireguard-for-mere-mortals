# What WireGuard Is

**WireGuard** is a way for two machines
that hold each other's keys to talk as if
a private wire ran between them — over
ordinary internet connections, encrypted
end to end. Each machine gets an address
on a small private network that exists
only inside the tunnel, and packets for
that network are wrapped, encrypted, and
sent as ordinary UDP to the other side,
which unwraps them.

That is the whole shape. The rest of
this guide is the working detail: keys,
config files, routing, and what to do
when the wire stays silent.

## A protocol, not a service

WireGuard is three things with one name:
a **protocol** (the wire format and the
cryptography), an **implementation** of
it in the Linux kernel — with cousins
for other systems — and two small tools,
`wg` and `wg-quick`, that configure it.

What it is *not* is a service. There is
no WireGuard company running servers for
you, no account to create, no login, no
subscription, no dashboard. Nothing
phones home; there is no home to phone.
Nobody assigns your addresses, keeps a
directory of your machines, or can turn
your network off. If you've used a
commercial VPN or a mesh tool built on
WireGuard — Tailscale is the one this
series has a guide to — those are
services *around* the protocol. This
guide is about the protocol itself, run
by hand, which means the chores those
services automate are yours here. In
exchange, nothing about your network
depends on anybody else's computers
staying up, or on anybody else's idea
of the right keys.

## The three ideas, previewed

Everything in WireGuard falls out of
three concepts, one per coming chapter:

1. **Keys.** Every machine generates a
   private key it never shares and a
   public key it hands out freely.
   Identity *is* the key pair: there are
   no usernames, no certificates, no
   passwords (chapter 2).
2. **Peers.** Each machine lists the
   machines it will talk to — a public
   key, and where that machine can
   currently be reached. A packet from
   an unknown key isn't rejected with an
   error; it's dropped in silence,
   because there is nothing to say to
   someone who isn't on the list.
3. **AllowedIPs.** For each peer, the
   addresses that peer is allowed to
   use. This one list does two jobs at
   once — it is the routing table *and*
   the access check — and chapter 6 is
   devoted to it, because most real-world
   WireGuard confusion lives there.

## Silent by design

A consequence worth knowing early: a
WireGuard interface answers *nothing*
it can't authenticate. No greeting, no
error, no "connection refused." To a
port scanner, a machine listening for
WireGuard looks exactly like a machine
with nothing there at all. This is a
security property — there's no surface
to probe — and it is also why debugging
a tunnel is an exercise in reading your
own side's state (chapter 7) rather
than asking the other side what went
wrong. The other side, by design, isn't
saying.

## What it can't do

- **It doesn't find your machines.**
  No discovery, no directory, no
  rendezvous. You declare peers and
  endpoints yourself, and when an
  endpoint's address changes, chapter
  11 explains what heals and what
  doesn't.
- **It doesn't cross every NAT by
  itself.** One side of a conversation
  must be reachable — a stable address,
  a forwarded port — or already talking.
  There is no relay to fall back to.
- **It isn't anonymity.** The hub sees
  the spoke's real address; the spoke's
  traffic exits wherever the tunnel
  sends it. WireGuard encrypts a path;
  it doesn't disguise who's walking it.
- **It isn't a firewall.** AllowedIPs
  binds addresses to keys, and that's
  the whole access model. Rules about
  ports and programs live in your
  ordinary firewall, next door.

## The lab

The guide is practised on a laboratory
of two interfaces on one machine — a
**hub** (`10.99.0.1`) and a **spoke**
(`10.99.0.2`) — because the parts being
taught are identical to a two-machine
setup; only one endpoint address would
differ. `examples/lab.sh` builds it;
chapter 3 builds it by hand once, to
show the moving parts. The build
machine for this guide lives in a
sandbox that refuses to send UDP at
all, so its tunnels come up perfectly
configured and never complete a
handshake — that failure is captured
and taught from, not hidden, and
`criteria.md` keeps the ledger of what
was run versus what is described.
