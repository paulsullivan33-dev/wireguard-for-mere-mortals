# Glossary

**AllowedIPs** — the per-peer list of
tunnel addresses. Outbound, it's the
routing table (which peer gets this
packet); inbound, it's the access
check (which addresses this peer may
claim as source). One list, two jobs;
chapter 6.

**Cryptokey routing** — WireGuard's
name for binding addresses to keys so
that routing and authentication are
the same table — AllowedIPs, above.

**Endpoint** — where a peer can
currently be reached on the ordinary
network: an address and UDP port.
Only the initiating side needs one in
its config; the other side learns it
from arriving packets.

**Full tunnel** — a spoke config whose
AllowedIPs is `0.0.0.0/0` (and `::/0`):
all traffic crosses the tunnel and
exits at the hub. Chapter 9.

**Handshake** — the two-message
exchange that starts (and periodically
refreshes) a session between peers,
proving both hold their private keys
and agreeing fresh session keys. Retry
interval five seconds; routine rekey
after about two minutes of sending.

**Hub** — this guide's name for the
peer with the stable, reachable
address that others initiate to. Not
a WireGuard term — WireGuard knows
only peers — but the role is real.

**Keepalive (PersistentKeepalive)** —
an empty packet sent every N seconds
to keep a NAT mapping warm, so the
far side can still reach in. Set on
the side behind NAT.

**Kill switch** — a posture, not a
feature: routing plus firewall rules
arranged so that if the tunnel drops,
traffic fails instead of falling back
to the open connection. Chapter 10.

**ListenPort** — the UDP port an
interface listens on. 51820 by
convention, not by requirement.

**MTU** — maximum transmission unit;
the largest packet a link carries.
WireGuard's wrapper costs 60 bytes
per packet on IPv4 (80 on IPv6), so
tunnel interfaces default to 1420 on
a 1500-byte path. Chapter 12.

**NAT mapping** — the temporary entry
a NAT keeps for a UDP conversation.
Expires when idle; when it dies, the
machine behind the NAT can't be
reached first. Keepalive exists
because of this entry.

**Peer** — one machine in another
machine's config: a public key, plus
optionally a preshared key, an
endpoint, and an AllowedIPs list.

**Preshared key (PSK)** — a symmetric
secret shared by one pair of peers
and mixed into their handshake as an
additional gate. One per pair.

**Private / public key** — the two
halves of a machine's identity. The
private key never leaves the machine;
the public key is handed to every
peer and is, to WireGuard, the
machine's name.

**Silent by design** — WireGuard
answers nothing it can't
authenticate. A listening interface is
indistinguishable from an absent one
to any probe.

**Split tunnel** — a spoke config
whose AllowedIPs names only the
destinations the tunnel is for;
everything else uses the local
connection. Chapter 9.

**Spoke** — the initiating peer,
usually the one behind NAT or on the
move. Companion term to hub.

**Tunnel address** — a machine's
address inside the tunnel's private
subnet (the lab's `10.99.0.x`),
assigned by you, unrelated to its
ordinary network address.

**Userspace implementation** —
`wireguard-go`: WireGuard running as
a program instead of in the kernel,
for systems without the module.
Same protocol, same tools; wg-quick
falls back to it automatically.
