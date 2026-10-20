# Your First Tunnel

Time to build the lab: two interfaces,
one machine, everything by hand once.
Readers with two real machines should
follow along on both — every step is the
same except one endpoint address.
`examples/lab.sh` does all of this in
one go if you'd rather look before you
leap; this chapter is the leap, taken
slowly.

The roles: a **hub**, the machine with
the stable address that waits and
listens, and a **spoke**, the machine
that reaches out. In the lab the hub is
`wg-hub` (tunnel address `10.99.0.1`,
listening on UDP 51820) and the spoke
`wg-spoke` (`10.99.0.2`, port 51821).
Keys for both were made in chapter 2.

## The two configs

WireGuard itself is configured with a
bare config — private key, port, peers.
(The friendlier format with addresses
and DNS in it belongs to `wg-quick`, and
is chapter 5.) The hub's:

```
$ cat hub.setconf     (the hub: waits, listens on 51820, knows one peer)
[Interface]
PrivateKey = WJP+1ao1vKZXQXuIwfV1Mmc0g/wjDs2X02PWveahLUU=
ListenPort = 51820

[Peer]
PublicKey = rl3NB9ayaoVXhB6XhivPev+vFeB7MWIRXHS6D9+Ocnk=
PresharedKey = 0Zwy1iZnxbVK2P5GHeOmslWiPcB1XDPprARzBNRCDqM=
AllowedIPs = 10.99.0.2/32
```

(Those are the lab's real keys, printed
because the lab is thrown away after the
build. Yours stay in root-only files and
out of documents — chapter 2.)

And the spoke's, with one line the hub
doesn't have:

```
$ cat spoke.setconf   (the spoke: dials the hub at 127.0.0.1:51820)
[Interface]
PrivateKey = ULTwjeXBGfblDFc1fL1y8+Wi01Tgw2t67FYukG08a10=
ListenPort = 51821

[Peer]
PublicKey = EJPFrOuf2htTsqfWifCIvP4VakyU0s59jO+CF0HK9Cs=
PresharedKey = 0Zwy1iZnxbVK2P5GHeOmslWiPcB1XDPprARzBNRCDqM=
Endpoint = 127.0.0.1:51820
AllowedIPs = 10.99.0.1/32
```

**`Endpoint`** is where this peer can
currently be reached — an ordinary
internet address and UDP port. The hub
has none for the spoke: it will learn
the spoke's endpoint from the spoke's
own first packets, which is why a hub
can serve laptops that move and
renumber. On a real network the spoke's
endpoint here would be the hub's public
address; the lab uses loopback, and
that is the only unreal thing about
this setup.

## Bringing the interfaces up

On an ordinary Linux machine the kernel
does the work and the interfaces are
created with `ip link add wg-hub type
wireguard`. The build machine has no
kernel module — the sandbox it's built
in strips it — so it runs the userspace
implementation, `wireguard-go`, which
presents the same interfaces and takes
the same commands (`wg-quick` falls
back to it the same way, as chapter 5
shows). The steps, condensed from the
build capture (kept whole in the
transcripts with this guide):

```
$ wireguard-go wg-hub; wireguard-go wg-spoke
$ wg setconf wg-hub hub.setconf; wg setconf wg-spoke spoke.setconf
$ ip address add 10.99.0.1/32 dev wg-hub; ip address add 10.99.0.2/32 dev wg-spoke
$ ip link set wg-hub up; ip link set wg-spoke up
$ ip route add 10.99.0.1/32 dev wg-spoke; ip route add 10.99.0.2/32 dev wg-hub
$ ip route show | grep 10.99
10.99.0.1 dev wg-spoke scope link
10.99.0.2 dev wg-hub scope link
```

Two steps deserve a stare:

- **`wg setconf`** loads a config into
  a live interface. It *replaces* the
  whole configuration — it never merges
  — a fact chapter 6 relies on and
  chapter 13 repairs with.
- **Addresses are not WireGuard's job.**
  The config has no `Address` line;
  `ip address add` gives each interface
  its tunnel address, and `ip route`
  decides what enters the tunnel. The
  lab's routes look backwards — each
  tunnel address routed out the *other*
  interface — because one machine is
  playing both parts: to talk to the
  hub you send through the spoke. On two
  machines, each simply routes the
  tunnel network at its own interface,
  which is what `wg-quick` sets up for
  you (chapter 5).

## The before picture

Configured, addressed, up — and silent.
This is the state every new tunnel
passes through, captured as-is:

```
$ wg show wg-hub   (BEFORE any traffic: peer known, no handshake yet)
interface: wg-hub
  public key: EJPFrOuf2htTsqfWifCIvP4VakyU0s59jO+CF0HK9Cs=
  private key: (hidden)
  listening port: 51820

peer: rl3NB9ayaoVXhB6XhivPev+vFeB7MWIRXHS6D9+Ocnk=
  preshared key: (hidden)
  allowed ips: 10.99.0.2/32
```

The peer is known, the keys are loaded,
and there is no `endpoint`, no `latest
handshake`, no `transfer` — because no
packet has ever crossed. WireGuard does
nothing at idle: no greeting, no
keepalive, no background chatter, until
traffic asks it to. "Up" describes the
interface, not the conversation.

## First contact — and the build machine's wall

On an unrestricted machine, the next
thirty seconds go like this (described,
not captured — the reason is the rest of
this section): you ping the other
tunnel address, the first packet makes
the spoke introduce itself to the hub in
a **handshake** — a two-message
exchange, well under a second — and
`wg show` gains three lines:
`endpoint: 127.0.0.1:51821` on the hub
(learned from the spoke's packets),
`latest handshake: a few seconds ago`
on both, and `transfer:` counters
counting real bytes both ways. From
then on the tunnel is just a network:
SSH, file shares, and pings use the
`10.99` addresses and never know the
wire was encrypted.

On the build machine, the ping never
leaves the starting blocks:

```
$ ping -c 3 10.99.0.1   (the hub address, reached out through the spoke interface)
ping: connect: Operation not permitted
```

The sandbox forbids sending UDP — and
ICMP — at the operating-system level,
verified independently of WireGuard
with a two-line probe (chapter 14 has
it). A handshake is two UDP datagrams,
so on this machine it cannot happen,
full stop. Nothing above is mis-built:
the interfaces, configs, and state are
all real, and the daemon's own log —
handshake initiations attempted every
five seconds, each refused by the OS —
is captured in chapter 14, where it
belongs, because a firewall doing this
to you looks exactly the same from the
inside.

Check: `wg show` on your machine lists
the peer you configured, with the
allowed IPs you wrote; on any network
that passes UDP, the first ping to the
tunnel address answers, and `latest
handshake` appears. If the first line
of that check fails, the config didn't
load — chapter 14 starts there.
