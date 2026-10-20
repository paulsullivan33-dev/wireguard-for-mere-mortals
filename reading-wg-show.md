# Reading wg show

A WireGuard tunnel gives you no login
prompts, no error pages, and — chapter
1's warning — no answers at all from
the other side when something's wrong.
What it gives you is `wg show`: the
complete state of your side, which
turns out to be enough, if you read it
field by field. This is the chapter
the troubleshooting chapter (14) keeps
sending you back to.

## The interface block

```
interface: wg-hub
  public key: EJPFrOuf2htTsqfWifCIvP4VakyU0s59jO+CF0HK9Cs=
  private key: (hidden)
  listening port: 51820
```

Your public key (check it against what
your peers hold — a mismatch is chapter
14's first suspect), your private key
present but never printed, and the UDP
port you're listening on. If the port
isn't the one your peers' endpoints
name, nothing else in this chapter
will save you.

## The peer block

Chapter 3's "before" picture had three
lines per peer. A peer that has lived
shows up to six:

| Line | What it tells you |
|---|---|
| `preshared key: (hidden)` | A PSK is set (chapter 2). Absent line, none is. |
| `endpoint: 127.0.0.1:51821` | Where this peer currently is, as far as you know — configured on the initiating side, *learned* from arriving packets on the other. A hub's endpoint for a roaming laptop is the laptop's last known whereabouts, not a promise. |
| `allowed ips: 10.99.0.2/32` | Chapter 6's list for this peer. `(none)` here is a five-alarm reading. |
| `latest handshake: 1 minute, 12 seconds ago` | When the last handshake *completed*. The single best health line in the tool. |
| `transfer: 4.21 MiB received, 3.87 MiB sent` | Data bytes since the interface was created, both directions, counted after decryption/before encryption — real payload, not wire overhead. |
| `persistent keepalive: every 25 seconds` | Keepalive is on for this peer (chapter 11). |

## Reading health from three lines

**Handshake age.** Under traffic,
WireGuard re-handshakes routinely —
a fresh handshake is initiated after
about two minutes of sending (a
protocol constant, not a setting), so
on a working tunnel the age sits
between seconds and a couple of
minutes. Hours means the conversation
is stale or one-way; *no line at all*
means a handshake has never completed
since the interface came up — the
tunnel has carried nothing, whatever
the config claims.

**Transfer, split by direction.** Both
counters growing: traffic flows both
ways. Sent growing, received stuck at
the same value (or `0 B`): your
packets leave and nothing comes back —
chapter 6's one-way tunnel, or the
return path is being eaten (chapter
14). Received without sent means the
peer is initiating to you.

**Endpoint plausibility.** On the
responding side, the endpoint is
learned, so it changes when the peer
roams — that's the healing behaviour
of chapter 11, visible. On the
initiating side it's your configured
value; if the hub moved and you
didn't, this line is the stale fact.

## Narrower views and the machine-readable one

`wg show` answers sub-questions
directly — `wg show wg-hub allowed-ips`,
`... endpoints`, `... latest-handshakes`,
`... transfer` each print just that
column for scripting and quick checks.
The catch-all is the dump:

```
$ wg show all dump   (the machine-readable form, for scripts)
wg-spoke	EJPFrOuf2htTsqfWifCIvP4VakyU0s59jO+CF0HK9Cs=	0Zwy1iZnxbVK2P5GHeOmslWiPcB1XDPprARzBNRCDqM=	127.0.0.1:51820	10.99.0.1/32	0	0	0	25
```

(one peer line shown; each interface
also gets a line whose second column
is its **private key, in plaintext**,
followed by its public key, port, and
fwmark). Tab-separated, documented
column order, made for tools. Treat
dump output like a config file: it
contains private keys, so it doesn't
go in tickets, chats, or screenshots.
The pretty `wg show` hides them
precisely so you can share *it* when
asking for help.

And `wg showconf <iface>` (chapter 4)
prints the config the interface
actually holds — the third leg of
diagnosis: the file you wrote, the
config the machine holds, and the
state the traffic produced. Chapter
14 is mostly the art of comparing
those three.

Check: on a tunnel you believe is
healthy, `wg show` shows a handshake
newer than a few minutes, transfer
growing in both directions when you
send traffic, and an endpoint you
recognise. Any one of the three being
wrong names a different failure —
which is the whole of chapter 14's
method.
