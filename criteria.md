# Writing Criteria

Every guide in this repo is written to the same
standard. If you're adding or editing a guide —
human or AI — hold it to these.

1. **Plain words, real ideas.** Simple language,
   never dumbed-down concepts. Explain jargon on
   first use; collect terms in the glossary.
2. **No hype.** No marketing adjectives, no
   "revolutionary," no promises about what
   something will do for the reader.
3. **Honest about limits.** Say what the thing
   *can't* do. State uncertainty instead of
   smoothing it over. Validation notes include
   what remains unverified.
4. **No invented numbers.** Benchmarks, defaults,
   and specs are either measured or qualified with
   "depends on your setup." If it wasn't tested,
   say so.
5. **Checkable.** Commands are meant to be run,
   with "Check:" blocks showing what success looks
   like. Sources are linked, not asserted.
6. **Respect the reader's setup.** Call out
   Windows/Mac/Linux differences. Don't assume a
   GPU, a budget, or prior experience.
7. **Safety isn't skipped.** Real risks get
   stated plainly, not buried.
8. **Scoped.** Each guide says what it covers and
   points elsewhere for the rest. No guide
   pretends to be the whole subject.
9. **Structure over prose.** Tables, before/after
   examples, symptom → fix. Scannable beats essay.

## Verification notes for this guide

Standard 3 and 4 applied to this guide,
specifically. The build machine ran Ubuntu
24.04 as root, kernel 7.0.0-39-generic, with
**wireguard-tools v1.0.20210914** and
**wireguard-go v0.0.20230223** installed
fresh for the build (`apt-get install
wireguard-tools wireguard-go`). Every quoted
output in the chapters is a capture from
those tools, run against the shipped lab.
Working transcripts are kept with the build
(`wireguard-lab/transcripts/`, numbered
01–14).

**The lab.** Two WireGuard interfaces on one
machine — `wg-hub` (10.99.0.1, UDP 51820)
and `wg-spoke` (10.99.0.2, UDP 51821) — the
spoke's peer endpoint pointing at the hub
over loopback, a preshared key on the pair.
`examples/lab.sh` rebuilds it and was run
end-to-end on the build machine (up, down,
up again reusing keys) before shipping.

**The sandbox, stated once.** Three
refusals shape everything below, each
captured rather than hidden:
(1) the WireGuard kernel module does not
exist here — `modprobe` reports it not
found, `ip link add type wireguard`
answers "Unknown device type" — so all
interfaces are the userspace
implementation, wireguard-go, which the
sandbox permits and wg-quick falls back
to on its own;
(2) network namespaces cannot be entered
(`setns: Operation not permitted`), so
the two-machines-on-one-box lab uses two
interfaces in one namespace instead;
(3) the runtime forbids sending UDP
datagrams and ICMP at the OS level —
reproduced independently of WireGuard
with a Python probe (UDP `sendto` →
`Operation not permitted`, ICMP socket →
`Permission denied`, TCP connect → OK).
Consequence: on the build machine no
handshake can ever complete, because a
handshake is two UDP datagrams. The
guide therefore teaches the handshake
from the daemon's own debug log —
initiations attempted every five seconds,
each refused by the OS — and describes
the success state, labelled as described
wherever the distinction matters.
Everything that does not require a packet
to actually cross — keys, configs,
interface lifecycle, live peer edits,
state inspection — was run for real.

One environment note, for the record:
the sandbox dropped the wireguard-tools
package between build sessions once
(`wg: command not found` observed
mid-build); it was reinstalled and every
capture after that point postdates the
reinstall. Same upstream version
throughout.

**Verified by running, per chapter:**

- *Ch. 1:* no commands; its sandbox
  claims are the probes in transcripts
  02, 03, and 08.
- *Ch. 2:* `wg genkey` ×2, file modes
  under umask 077 (`-rw-------`, 45
  bytes), `wg pubkey` derivations for
  both lab machines, `wg genpsk`,
  the 45-byte `wc -c` table.
- *Ch. 3:* both setconf files as
  printed; wireguard-go bring-up,
  `wg setconf` ×2, both addresses,
  both routes, and the route table;
  the "before" `wg show wg-hub` —
  peer present, no endpoint, no
  handshake, no transfer; the ping
  refusal line.
- *Ch. 4:* `wg showconf` for both
  interfaces, quoted whole; the field
  tables' claims cross-checked
  against ch. 5's strip output (what
  `wg` itself keeps vs. what is
  wg-quick's).
- *Ch. 5:* `wg-quick strip` of the
  lab spoke config (Address and DNS
  removed, the rest intact);
  `wg-quick up` of a minimal config,
  including the kernel probe failure
  and the userspace fallback
  narration; `wg show` and the link
  line (MTU 1420) while up;
  `wg-quick down` and the device's
  verified absence afterwards. The
  shipped `examples/hub.conf` and
  `examples/spoke.conf` were also
  parse-tested with real keys
  substituted for their placeholders:
  both strip clean.
- *Ch. 6:* the AllowedIPs theft —
  a third peer claiming the spoke's
  `10.99.0.2/32` succeeded with exit
  0 and moved the address (victim
  peer left at `(none)`); removing
  the thief did not restore it;
  repair by wholesale `wg setconf`
  restore, verified with
  `wg show wg-hub allowed-ips`;
  `wg show all dump`, including the
  fact that it prints private keys.
- *Ch. 7:* every `wg show` block
  quoted is from transcripts 06, 11,
  or 14; the dump's one quoted peer
  line is verbatim.
- *Ch. 8:* no captures — shapes and
  address planning only; forwarding
  and NAT are in the
  documented-only list below.
- *Ch. 9:* no new captures; the
  split-tunnel shape is the lab's
  own (ch. 3/5); full-tunnel routing
  mechanics are documented-only
  below.
- *Ch. 10:* the `DNS =` line's
  consumption by wg-quick is ch. 5's
  strip capture; the resolver switch
  itself and the kill-switch rules
  are documented-only below.
- *Ch. 11:* `wg set` adding
  `persistent-keepalive 25` to a
  live peer, and the line appearing
  in `wg show`; a forced 5-second
  keepalive driving the initiation
  retries of ch. 14's log.
- *Ch. 12:* MTU 1420 as created —
  the link line from the userspace
  probe interface and wg-quick's
  own `ip link set mtu 1420`
  narration; the 60/80-byte wrapper
  figures are the protocol's
  published overhead (whitepaper),
  stated as such in the chapter.
  The ping sweep is documented-only.
- *Ch. 13:* rotation's component
  operations (key generation, live
  `wg set`, peer removal, setconf
  replacement, an on-purpose
  AllowedIPs move) were each run in
  ch. 2/6/11's sessions; the full
  sequence assembled from them is
  labelled as assembled in the
  chapter.
- *Ch. 14:* the daemon debug log
  (handshake initiations and the
  OS's refusal, every five seconds),
  the Python send probe, and
  cross-references to ch. 3/6/7/11
  captures. No symptom in the
  chapter lacks either a capture
  here or a pointer to one.

**Capture hygiene (declared trims):**
chapter 3 condenses the bring-up
command sequence into a list and says
so in its text (the whole capture,
banner and echoes included, is
transcript 06); the AllowedIPs theft
block in ch. 6 is cropped to the
load-bearing lines (the set, the
resulting `allowed-ips` view), with
the removal and restore in
transcripts; the `wg show all dump`
in ch. 7 shows one peer line verbatim
and describes the interface lines
rather than reprinting lab private
keys a second time — the full dump
is transcript 11; the daemon log in
ch. 14 is an excerpt whose startup
selection is declared in transcript
13's header (the five-second retry
pattern is shown complete, four
iterations). No output was completed,
corrected, or invented: where a
capture surprised the draft (wg-quick
succeeding via its fallback; the
overlap steal succeeding silently),
the chapters were written to the
capture.

**Documented-only (not run), and why:**

- *A completed handshake, and any
  traffic crossing a tunnel.* The
  sandbox refuses all UDP sends, so
  the two datagrams a handshake is
  made of cannot leave. The success
  state (endpoint learned, latest
  handshake, transfer counters
  moving) is described and labelled
  as described in ch. 3 and 7.
- *Ping or any tool's traffic through
  the tunnel, and the MTU DF ping
  sweep.* ICMP is refused by the
  same wall; the sweep is taught
  with its arithmetic (ch. 12).
- *Hub forwarding, NAT masquerade,
  spoke-to-spoke and spoke-to-LAN
  reachability (ch. 8), and the
  hub's forwarding half of a full
  tunnel (ch. 9).* All need packets
  to cross and kernel forwarding the
  sandbox can't exercise; the
  settings are named with their
  standard commands.
- *wg-quick's DNS resolver switching
  (ch. 10).* The build machine runs
  no resolver integration for
  wg-quick to drive; the `DNS =`
  line's consumption by strip is
  captured, the switch is described
  from wg-quick's documentation.
- *The kill-switch PostUp/PreDown
  rules (ch. 10).* Quoted as a
  pattern from the official
  documentation's example; not run,
  and the chapter says to practise
  them on a machine you can walk to.
- *The systemd unit
  `wg-quick@wg0` (ch. 5).* The
  sandbox is not a systemd host; the
  enable command is the documented
  standard one.
- *A full tunnel's routing-table
  arrangement (ch. 9) and DNS-name
  endpoint re-resolution via
  `reresolve-dns.sh` (ch. 11).*
  Described from wg-quick's
  documentation; both need a live
  tunnel or a moving endpoint to
  demonstrate.
- *The key-rotation sequence end to
  end (ch. 13).* Assembled from
  individually captured operations,
  labelled in the chapter; the lab's
  keys being throwaway, rotating
  them would prove nothing the
  components didn't.
- *Windows, macOS, iOS, and Android
  WireGuard.* Official apps exist
  and read the same config format;
  no such device was available to
  the build. The guide's hands are
  Linux hands and it says so.

Lab discipline, for the record: every
interface, probe, and listener in this
guide is on the build machine itself,
over loopback; nothing external was
contacted, scanned, or configured.
All keys appearing in transcripts and
in ch. 3's config quotes are throwaway
lab keys, generated for the build;
both lab interfaces and daemons were
torn down when the build finished,
and the shipped examples carry
`<placeholders>`, never keys.
