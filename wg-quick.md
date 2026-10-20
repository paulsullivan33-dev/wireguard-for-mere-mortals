# wg-quick

Chapter 3 built a tunnel the manual
way so you could see the parts. Nobody
should have to do that twice. **`wg-quick`**
is the standard front end: it reads one
config file — the dialect from chapter
4, extras and all — and performs the
whole bring-up: create the interface,
hand the stripped config to `wg`, assign
the addresses, add the routes, set the
MTU, run your hooks, and arrange DNS if
asked. `wg-quick down` unwinds it.

Configs live in `/etc/wireguard/`, named
for their interface: `wg0.conf` is
interface `wg0`. The directory and the
files are root-only — they contain
private keys (chapter 2) — mode `600`
on the files, always. The `examples/`
directory of this guide ships the
lab's hub and spoke in this format.

## What it does with the extras

`wg-quick strip` prints exactly what
wg-quick will hand to `wg` — the extras
removed. Captured on the lab's spoke
config:

```
$ wg-quick strip wgquick/wg-spoke.conf   (what wg-quick would hand to wg itself)
[Interface]
PrivateKey = ULTwjeXBGfblDFc1fL1y8+Wi01Tgw2t67FYukG08a10=
ListenPort = 51821

[Peer]
PublicKey = EJPFrOuf2htTsqfWifCIvP4VakyU0s59jO+CF0HK9Cs=
PresharedKey = 0Zwy1iZnxbVK2P5GHeOmslWiPcB1XDPprARzBNRCDqM=
Endpoint = 127.0.0.1:51820
AllowedIPs = 10.99.0.1/32
PersistentKeepalive = 25
```

The input's `Address` and `DNS` lines
are gone — they were never `wg`'s.
They're wg-quick's instructions to
*itself*, consumed during bring-up:
`Address` becomes `ip address add`,
`DNS` becomes a resolver change (via
`resolvconf` where the system offers
one), `AllowedIPs` becomes routes,
`0.0.0.0/0` becomes a default-route
arrangement with a side routing table
so the tunnel's own packets don't chase
their own tail. When a tunnel behaves
strangely, `strip` plus chapter 4's
table is how you check what was
actually asked for.

## Up and down, captured

wg-quick narrates itself: each command
it runs is printed with a `[#]` prefix.
On the build machine, which has no
kernel module, watch the second line —
wg-quick notices, says so, and falls
back to the userspace implementation
by itself:

```
$ wg-quick up wgquick/wgq0.conf   (a minimal third config — the sandbox has no kernel module, so this is the honest outcome)
[#] ip link add wgq0 type wireguard
Error: Unknown device type.
[!] Missing WireGuard kernel module. Falling back to slow userspace implementation.
[#] wireguard-go wgq0
[#] wg setconf wgq0 /dev/fd/63
[#] ip -4 address add 10.98.0.1/24 dev wgq0
[#] ip link set mtu 1420 up dev wgq0
```

On a normal machine the fallback lines
never appear; the rest is the chapter 3
sequence, automated — including the
`mtu 1420` that chapter 12 explains.
And down:

```
$ wg-quick down wgquick/wgq0.conf
[#] ip link delete dev wgq0
$ ip link show wgq0  (after down)
Device "wgq0" does not exist.
```

The narration is the feature. When
wg-quick fails halfway — a bad route, a
hook that errors — the last `[#]` line
is the step that failed, and the steps
after it never ran, which tells you
exactly what state you were left in.

## Running it as a service

For a tunnel that should exist whenever
the machine does, the systemd unit is
`wg-quick@<interface>`:

```
systemctl enable --now wg-quick@wg0
```

*(Documented, not run for this guide:
the build machine's sandbox is not a
systemd host. The command is the
standard one from the WireGuard
documentation.)* It does what the name
says — `wg-quick up wg0` at boot, down
at shutdown — and `systemctl status
wg-quick@wg0` plus `journalctl -u
wg-quick@wg0` are where its narration
goes to be read later.

Check: after `wg-quick up wg0`,
`wg show wg0` shows your peers and the
interface answers to its tunnel
address; after `down`, `ip link show
wg0` says the device does not exist —
partial states (address present but no
peers, peers but no routes) mean the
narration stopped mid-list, and the
last `[#]` line names where.
