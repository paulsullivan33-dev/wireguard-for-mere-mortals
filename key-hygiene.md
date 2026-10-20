# Key Hygiene

WireGuard keys don't expire. There is
no certificate authority to renew
with, no "valid until" date, no
prompt that will ever tap you on the
shoulder. That removes a whole class
of TLS-style surprises — and replaces
it with a discipline that is entirely
yours: the keys are good until *you*
change them, so hygiene is a habit,
not a deadline.

## The rules that matter

**One pair per machine, never shared.**
Chapter 2 said it as setup advice;
here is the enforcement reason. Two
machines holding the same private key
are one identity, and chapter 6's
routing makes that identity own one
address with one endpoint at a time —
the two copies will steal the tunnel
from each other as they take turns
talking. If a setup guide ever tells
you to copy a working config —
private key included — onto a second
machine "to save time," it's telling
you to build that fight. Generate a
fresh pair per machine; it's one
command.

**Revocation is deletion.** There is
no revocation list to publish. To
retire a machine — sold laptop, lost
phone, departed employee — delete its
`[Peer]` block from the hub (or
`wg set wg0 peer <pubkey> remove`
live; the remove was captured on the
lab in chapter 6's session). From
that moment the key is a stranger:
its packets get silence. On hub and
spoke, one edit revokes completely,
which is why the hub's config file is
the network's registry *and* its
lock.

**Back up the hub's configs like
crown jewels.** The hub's
`/etc/wireguard/` holds every peer's
public key, the hub's private key,
and every preshared key — the entire
network, re-buildable from that one
directory, and *impersonable* from
it too. Back it up, encrypted, with
the same care as the machine itself;
treat its loss two ways at once
(a restore you need, a leak you
fear). Spoke configs deserve the
same, one machine at a time.

**Never let keys travel as text.**
Not in chat, not in tickets, not in
a screenshot of `wg show all dump` —
which, chapter 7's warning bears
repeating, prints private keys in
plaintext. Public keys travel freely
but get verified (chapter 2); private
keys and preshared keys move only by
being typed or copied directly
between the two machines that hold
them, over a channel you already
trust.

## Rotation, as a procedure

Rotate a machine's pair when it might
have leaked, when the machine changes
hands, or on a cadence you choose —
annually is a sane household rhythm.
Chapter 6's theft mechanics make the
hub-side cut-over a one-liner, and
the whole dance is:

1. **On the machine:** generate the
   new pair (`wg genkey`, `wg pubkey`),
   and load it — replace `PrivateKey`
   in its config and `wg setconf`, or
   `wg-quick down`/`up` around the
   edit. The machine now speaks with
   the new key and, briefly, its peers
   don't know it.
2. **On each peer (the hub, for a
   spoke):** add the new public key
   with the machine's *same*
   AllowedIPs. The address moves to
   the new key instantly — chapter
   6's steal, used on purpose.
   Handshakes with the new key start
   succeeding; the old key now owns
   nothing.
3. **Remove the old peer entry**
   (`wg set ... peer <old> remove`,
   or delete the stale block), then
   shred the old private key file
   (`shred -u` where the platform has
   it) rather than leaving it in a
   backups folder forever.

*(The steps are assembled from
operations captured live in this
guide — `wg set`, setconf replacement,
peer removal, the AllowedIPs move —
but the full sequence wasn't run
end to end on the lab, whose keys are
throwaway by design. The order above
is the order that never strands you:
new key live on the machine first,
peers cut over second, old key
deleted last.)*

## If a key actually leaks

Assume the holder *is* that machine
until rotation completes: every peer
it has will accept it, and its
AllowedIPs are its to use. The
response is rotation with the order
flipped for urgency — remove the
peer entry on the hub *first* (the
machine goes dark, acceptably), then
re-key the machine, then re-add.
Also rotate that pair's preshared
key: the PSK was in the same file the
private key leaked from, so it leaked
too.

Check: you can point at, for every
machine, the file holding its private
key, its mode-`600` permissions, the
backup of the hub's config directory,
and the date each pair last changed.
If any of the four is "unknown," the
network's real state is unknown —
and chapter 14's problems will be
that much harder to see when they
come.
