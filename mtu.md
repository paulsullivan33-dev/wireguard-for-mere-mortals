# MTU

**MTU** — maximum transmission unit —
is the largest packet a link will
carry in one piece. It earns a short
chapter because WireGuard changes the
arithmetic on every packet it touches,
and because its failure mode is the
most misleading in this guide: a
tunnel where small things work and
big things quietly hang.

## The arithmetic

Every packet the tunnel carries gets
wrapped: an outer IP header, a UDP
header, WireGuard's own header, and an
authentication tag. The wrapper costs
**60 bytes** on an IPv4 path (20 IP +
8 UDP + 16 WireGuard header + 16 tag)
and **80 bytes** on IPv6 (the outer IP
header is 40). On the standard
1500-byte path, the largest packet
that fits *inside* the tunnel is
therefore 1440 bytes on IPv4 — and
both tools you met pick a safer number
by default. Captured on the build
machine's interfaces, created two
different ways (userspace daemon, and
wg-quick's own narration in chapter
5):

```
3: wgtest0: <POINTOPOINT,MULTICAST,NOARP> mtu 1420 qdisc noop state DOWN mode DEFAULT group default qlen 500
[#] ip link set mtu 1420 up dev wgq0
```

**1420** — sized so the tunnel works
even if the underlay turns out to be
IPv6 or a slightly smaller link. If
you know your path is 1500-byte IPv4
end to end, 1440 buys a little
throughput; if your path is smaller
than 1500 — PPPoE connections are
1492, and tunnels inside tunnels shed
more — the default may still be too
big, which is the next section.

## The symptom

Path MTU discovery is supposed to
handle all this: oversized packets
get a polite "too big, try smaller"
reply and everyone adjusts. On real
networks those replies are often
filtered by a middlebox, and the
result is a **black hole** with a very
specific signature:

- Pings answer. SSH connects. Small
  web pages load. The tunnel, by every
  quick check, *works*.
- Big things stall: long pages hang
  partway, file transfers freeze after
  a promising start, an SSH session
  dies the moment you `cat` something
  large.

The pattern — small passes, large
stalls — *is* the diagnosis. Don't let
the working ping talk you out of it.

## Measuring, and the fix

Find the true ceiling by offering the
tunnel packets of decreasing size with
"do not fragment" set: on Linux,
`ping -M do -s <size>` where size is
payload — add 28 (IP + ICMP headers)
to compare with MTU numbers. Walk the
size down from the interface MTU
until replies come back; the first
size that answers, plus 28, is your
path's real limit. *(Described: the
build machine's sandbox refuses ICMP
outright — chapter 3 hit that wall —
so the sweep is taught, not captured.
On your hardware it takes a minute.)*

Then fix whichever end is yours to
fix:

- **Set the tunnel MTU** below the
  measured path: an `MTU = 1380` line
  in the wg-quick config, or
  `ip link set wg0 mtu 1380` by hand.
  Lower than necessary costs a little
  efficiency; higher costs stalls.
  When in doubt, err low — a few
  percent of throughput is cheap
  insurance against a black hole.
- Networks with a known smaller link
  (the PPPoE case) can instead clamp
  TCP's segment size on the hub's
  forwarding path — a firewall rule
  (`--clamp-mss-to-pmtu` in iptables
  terms) that fixes TCP while leaving
  other traffic to the ping sweep's
  answer. Mention it to your future
  self in the hub config's comments;
  the tunnel MTU is the fix that
  travels with the config.

Check: with the tunnel up, a
deliberately large transfer — a big
file copy, a long web page — completes
at the same MTU the small checks
passed. If the big thing hangs while
the small ones fly, you haven't got a
WireGuard problem; you've got an MTU
problem wearing one.
