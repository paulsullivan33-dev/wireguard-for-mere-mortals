# Keys

Every WireGuard machine has exactly one
job before it can talk: make a key pair.
A **key pair** is two matched halves of
one secret — a **private key**, which
never leaves the machine, and a **public
key**, which you hand to every peer.
Anything encrypted to the public key can
only be decrypted with the private one,
and anything signed by the private key
checks out against the public one.
WireGuard uses this both ways at once:
the pair proves *who* a machine is and
seals *what* it says. There is no other
identity in the system — no hostname, no
account, no certificate with your name
in it. The public key is the name.

## Making a pair

Two commands, captured on the build
machine. Private keys land in files, so
set the file mask first — a key born
world-readable starts life compromised:

```
$ umask 077   (private keys land in files; keep them owner-only from birth)
$ wg genkey > hub.key
$ wg genkey > spoke.key
$ ls -l hub.key spoke.key
-rw------- 1 root nogroup 45 Oct 20 18:46 hub.key
-rw------- 1 root nogroup 45 Oct 20 18:46 spoke.key
$ wg pubkey < hub.key > hub.pub; wg pubkey < spoke.key > spoke.pub
$ cat hub.pub spoke.pub
EJPFrOuf2htTsqfWifCIvP4VakyU0s59jO+CF0HK9Cs=
rl3NB9ayaoVXhB6XhivPev+vFeB7MWIRXHS6D9+Ocnk=
```

Read the pieces:

- **`wg genkey`** prints one line: the
  private key, 44 characters of base64
  (32 bytes of Curve25519 key, encoded)
  ending in `=`. Both files above are
  45 bytes — 44 characters and a
  newline.
- **`wg pubkey`** reads a private key
  and derives the public half. The
  derivation is one-way: the public key
  cannot be run backwards into the
  private one, which is the entire
  reason you can hand it out.
- **One pair per machine.** Not per
  tunnel, not per peer — per machine.
  A machine with three peers still has
  one key pair; it's the *peers* who
  each hold a copy of its public key.

The compact form you'll see in the
wild makes the pair in one breath:
`wg genkey | tee laptop.key | wg pubkey > laptop.pub`.

## You can't tell them apart by looking

Private and public keys have the same
shape — 44 base64 characters. Nothing
in the string says which half it is.
The only labels are the filename you
chose and where the file lives. Two
habits follow:

- Name files so future-you knows:
  `hub.key` / `hub.pub`, or keep each
  machine's private key inside its
  config file (chapter 4) and only
  distribute `.pub` files.
- Treat any unlabeled key you find in a
  note or a chat log as **private until
  proven otherwise** — which means
  treat it as burned if it travelled
  anywhere public. Regenerating a pair
  costs a minute (chapter 13); an
  attacker with your private key *is*
  your machine, to every peer, forever
  until you change it.

Public keys travel freely but their
**authenticity** matters: a peer who is
handed the *wrong* public key for you
will happily build a tunnel to whoever
holds that key's private half. For
machines that matter, verify a new
public key over a second channel — read
it aloud, check it against a console
you already trust — the way you'd
verify an SSH fingerprint.

## The preshared key

One more key exists, optionally: the
**preshared key**, made by `wg genpsk`.
Unlike the key pair, it is symmetric —
the *same* value sits in both machines'
configs for a given pair of peers:

```
$ wg genpsk > lab.psk   (one optional preshared key for the hub<->spoke pair)
$ wc -c hub.key hub.pub lab.psk   (every key: 44 base64 chars + newline)
 45 hub.key
 45 hub.pub
 45 lab.psk
```

It is mixed into the handshake as an
additional secret, so an attacker needs
it *as well as* a private key to get
anywhere. WireGuard's documentation
frames it as a hedge — including
against future quantum attacks on the
key exchange — and as cheap insurance
it costs one line per peer. Rules:

- **One preshared key per pair.** Hub↔
  laptop and hub↔phone get different
  values, so losing one pair's secret
  exposes no other pair.
- **Both sides, same value, or no
  handshake.** A mismatch fails exactly
  like a wrong key pair does — silently,
  on both ends (chapter 14).
- It lives in the config next to the
  private key and gets the same
  handling: root-only file, no chats,
  no tickets.

Check: `wg pubkey < machine.key` prints
the same public key you gave your
peers, the private key file is mode
`600`, and each of your machines has a
*different* pair. If two machines share
a pair, they are — to WireGuard — one
machine, and chapter 13 is how you fix
it.
