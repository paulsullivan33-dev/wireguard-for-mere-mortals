# Reading the Config

A WireGuard config file is short enough
to read whole, and you should — it is
the entire network, in one file, in
plain text. This chapter takes the
format apart field by field. Two
dialects share the file: the lines `wg`
itself understands, and extra lines
only `wg-quick` understands (chapter
5). Telling them apart is most of
reading a config well.

## [Interface] — this machine

| Line | Whose | Meaning |
|---|---|---|
| `PrivateKey` | wg | This machine's private key (chapter 2). The only required line. |
| `ListenPort` | wg | The UDP port peers reach this machine on. Hubs always set it (51820 is the conventional choice); a spoke that only dials out may omit it and take a random port. |
| `FwMark` | wg | A routing mark stamped on the tunnel's own packets; leave unset unless a multi-table routing setup asks for it. |
| `Address` | wg-quick | The tunnel address(es) to assign the interface. Not a `wg` setting at all — chapter 3 set it with `ip address add` by hand. |
| `DNS` | wg-quick | A resolver to configure while the tunnel is up (chapter 10, with warnings). |
| `MTU` | wg-quick | Interface MTU override (chapter 12). |
| `Table` | wg-quick | Which routing table the routes go in, or `off`. Matters for full tunnels (chapter 9). |
| `PreUp`/`PostUp`/`PreDown`/`PostDown` | wg-quick | Shell commands run around interface changes — firewall rules and the kill switch live here (chapter 10). |
| `SaveConfig` | wg-quick | If `true`, wg-quick writes live changes back into this file on the way down — convenient, and it eats comments and reformats. Off unless you want it. |

## [Peer] — one other machine

One block per machine this one will
talk to. A hub with five spokes has
five blocks; a spoke usually has one.

| Line | Meaning |
|---|---|
| `PublicKey` | The peer's public key — its identity. Required. |
| `PresharedKey` | The pair's shared secret (chapter 2), if used. |
| `AllowedIPs` | The tunnel addresses this peer may use — routing table and access check in one list (chapter 6). A peer with none can handshake but carries no traffic. |
| `Endpoint` | Where the peer can currently be reached (`address:port`). Only the side that initiates needs it (chapter 11). |
| `PersistentKeepalive` | Send an empty packet every N seconds to keep NAT mappings warm (chapter 11). `off` or absent means never. |

## The file, read as a sentence

The spoke's live config, printed back
by the machine itself with
`wg showconf` — the ground truth of
what the interface holds, as opposed to
what a file claims:

```
$ wg showconf wg-spoke   (the config the daemon actually holds — note the live-set keepalive, and no Address anywhere)
[Interface]
ListenPort = 51821
PrivateKey = ULTwjeXBGfblDFc1fL1y8+Wi01Tgw2t67FYukG08a10=

[Peer]
PublicKey = EJPFrOuf2htTsqfWifCIvP4VakyU0s59jO+CF0HK9Cs=
PresharedKey = 0Zwy1iZnxbVK2P5GHeOmslWiPcB1XDPprARzBNRCDqM=
AllowedIPs = 10.99.0.1/32
Endpoint = 127.0.0.1:51820
PersistentKeepalive = 5
```

Read it the way chapter 3's files were
written: *"I hold this private key and
listen on 51821. The machine with that
public key may use 10.99.0.1, can
currently be reached at 127.0.0.1:51820,
and shares this preshared secret with
me."* Every WireGuard behaviour —
encryption, authentication, routing —
is a consequence of sentences like
that one, and `wg showconf` is how you
ask a running tunnel to say its
sentence back. When a tunnel misbehaves,
compare the two machines' sentences:
they must be mirror images, each naming
the other's key and an AllowedIPs the
other actually uses.

Two reading habits to keep:

- **`#` starts a comment**, and comments
  are the first casualty of tools that
  rewrite configs (`SaveConfig`, some
  GUIs). Keep your annotated master
  copy somewhere the tools don't write.
- **The private key is in this file, in
  plain text.** That's why configs live
  in root-only directories with mode
  `600`, and why a config is shared
  with nobody — you share *public
  keys*, and each side writes its own
  file.
