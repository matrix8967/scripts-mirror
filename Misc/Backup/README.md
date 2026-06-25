# Backup

Distro-agnostic, encrypted, compressed system backup pair. Captures package
inventories, desktop/session state, system metadata, and rsync-staged
tarballs of `/etc`, `$HOME`, and selected custom paths. Each archive is
compressed with `zstd` and encrypted with `gpg`.

```
backup-system.sh   # creates a session
restore-system.sh  # inspects, verifies, and restores a session
backup-lib.sh      # shared helpers (sourced)
excludes-home.txt  # rsync exclude patterns for $HOME
excludes-system.txt
```

## Why two scripts plus a library

- `backup-system.sh` is what you run on the machine being backed up.
- `restore-system.sh` is what you run on a freshly installed machine (or any
  recovery target) to bring it back.
- `backup-lib.sh` is sourced by both — it owns logging, TUI helpers,
  destination URL parsing, remote mounting, hashing.

## Defaults that matter

| Flag                                 | Default              | Why                                           |
|--------------------------------------|----------------------|-----------------------------------------------|
| `--dry-run`                          | **on**               | Prevents accidental writes.                   |
| One of `--gpg-recipient`, `--gpg-symmetric`, `--no-encrypt` | none — required | The script refuses to start without an explicit encryption decision. |
| `--zstd-level`                       | 19                   | Strong compression, still acceptable speed.   |
| Inventories                          | plain text           | So you can read them on a fresh install before decrypting anything. Pass `--encrypt-all` to wrap them. |

### Encryption modes

| Mode | Flag | When to use |
|------|------|-------------|
| Asymmetric (recommended) | `--gpg-recipient ID` | Day-to-day backups. Unattended runs — no passphrase prompt. Anyone with the secret key can decrypt. |
| Symmetric                | `--gpg-symmetric`    | One-off backups when you don't have a key. Script prompts once for a passphrase and reuses it for every archive. |
| **None**                 | `--no-encrypt`       | The destination is *already* encrypted (LUKS, encrypted NAS/SMB share, BitLocker), or the data is low-sensitivity (router config, etc.). Archives are plain `.tar.zst`. **The script prints a loud warning before and after the run.** |

`--no-encrypt` exists because layering gpg on top of an already-encrypted target wastes CPU on small devices and gives a false sense of "extra" security. Use it when the threat model is "the disk gets stolen" and disk-level encryption already addresses that.

## Quickstart

```sh
# preview a backup to a local SSD (nothing is written)
./backup-system.sh --dest /mnt/backup --gpg-recipient alex.m@controld.com

# run for real
./backup-system.sh --dest /mnt/backup --gpg-recipient alex.m@controld.com --execute

# remote (CIFS) destination, key encryption
./backup-system.sh \
    --dest smb://nas.local/backups/witchhammer \
    --smb-credentials ~/.smbcreds \
    --gpg-recipient alex.m@controld.com \
    --execute

# remote (NFS), passphrase encryption
./backup-system.sh \
    --dest nfs://nas.local/volume1/backups \
    --gpg-symmetric --execute

# unencrypted backup to an already-encrypted destination (LUKS-backed drive,
# encrypted NAS share). The script will print a loud warning at the start
# and again at the end. Output files are .tar.zst (no .gpg layer).
./backup-system.sh \
    --dest /mnt/luks-backup \
    --no-encrypt --execute
```

## Destination URLs

`--dest` accepts:

- A plain local path: `/mnt/backup`
- `file:///mnt/backup`
- `smb://[user@]host/share[/subpath]` — mounted via `mount.cifs`
- `cifs://[user@]host/share[/subpath]` — alias of `smb://`
- `nfs://host/exported/path` — mounted via `mount.nfs`

Remote schemes mount under a temp dir for the duration of the run and
unmount on exit (including on Ctrl-C / errors). Mounting requires `sudo`.

CIFS credentials: pass `--smb-credentials FILE`, where `FILE` follows the
standard kernel format:

```
username=alex
password=hunter2
domain=WORKGROUP
```

`chmod 600 ~/.smbcreds` is mandatory on most kernels.

## Sections

| Section    | Contents                                                                  |
|------------|---------------------------------------------------------------------------|
| `packages` | Inventories from apt/dnf/pacman/zypper/apk/flatpak/snap/pipx/cargo/go/npm/gem/asdf/rustup |
| `desktop`  | `dconf dump`, `$XDG_*` environment, GNOME extensions, KDE/X probes        |
| `system`   | `uname`, `os-release`, `lsblk`, `lspci`, `efibootmgr`, systemd units, IP tables |
| `etc`      | rsync of `/etc` → `etc.tar.zst.gpg`                                       |
| `home`     | rsync of `$HOME` → `home.tar.zst.gpg` (heavy excludes — see file)         |
| `custom`   | rsync of `/usr/local/etc /opt /var/spool/cron /root` → `custom.tar.zst.gpg` |

Skip with `--skip etc,custom` or whitelist with `--include packages,desktop`.
Add extra paths to `custom` with repeated `--custom-path /srv` flags.

## Output layout

```
<dest>/witchhammer-2026-05-07T123456Z/
  manifest.json
  SHA256SUMS
  SHA256SUMS.sig            (asymmetric mode only)
  packages/                 (plain-text unless --encrypt-all)
    apt-manual.txt
    flatpak.txt
    cargo.txt
    go.txt
    ...
  desktop/
    dconf-dump.ini
    session.env
    ...
  system/
    uname.txt
    fstab
    lsblk.txt
    ...
  configs/
    etc.tar.zst.gpg          # or etc.tar.zst when --no-encrypt
    home.tar.zst.gpg         # or home.tar.zst
    custom.tar.zst.gpg       # or custom.tar.zst
```

When `--no-encrypt` is used:
- Archives drop the `.gpg` extension and the gpg layer entirely.
- `SHA256SUMS.sig` is *not* produced (no key context to sign with).
- `restore-system.sh` auto-detects which extension is present per archive.

Permissions after a successful run: session dir `0500`, archives `0400`,
manifest/sums `0444`. Pass `--immutable` to also `chattr +i` the archives
(ext4/xfs/btrfs only; requires root).

## Restoration

`restore-system.sh` is a subcommand-style CLI. All mutating modes default
to `--dry-run`.

```sh
# what backups exist on this share?
./restore-system.sh list --dest /mnt/backup

# look at one without decrypting anything
./restore-system.sh inspect /mnt/backup/witchhammer-2026-05-07T123456Z

# integrity check
./restore-system.sh verify /mnt/backup/witchhammer-2026-05-07T123456Z

# replay packages (preview)
./restore-system.sh packages /mnt/backup/witchhammer-2026-05-07T123456Z \
    --include apt,flatpak

# replay packages (for real)
./restore-system.sh packages /mnt/backup/witchhammer-2026-05-07T123456Z \
    --include apt,flatpak --execute

# stage configs to a scratch dir + diff vs live filesystem
./restore-system.sh configs /mnt/backup/witchhammer-2026-05-07T123456Z \
    --archives home --execute

# only after reviewing the staged tree:
./restore-system.sh configs /mnt/backup/witchhammer-2026-05-07T123456Z \
    --archives home --apply-in-place --execute
```

The configs subcommand never writes to `/` without `--apply-in-place`.

## Raw CLI equivalents

The scripts orchestrate; nothing they do is magic. The same operations
by hand:

```sh
# inventories (a few examples)
apt-mark showmanual                              > apt-manual.txt
dpkg --get-selections                            > apt-selections.txt
flatpak list --columns=application,origin,branch,arch --app > flatpak.txt
flatpak remotes --columns=name,url               > flatpak-remotes.txt
pipx list --short                                > pipx.txt
cargo install --list                             > cargo.txt
dconf dump /                                     > dconf-dump.ini
gnome-extensions list --enabled                  > gnome-extensions.txt
go version -m $(ls "$(go env GOPATH)"/bin/*) \
    | awk '/^\tpath\t/ {print $2}' | sort -u     > go.txt

# stage /etc and $HOME with rsync (preserve attrs, follow exclude file)
rsync -aHAX --numeric-ids --relative \
    --exclude-from=excludes-system.txt \
    /etc /mnt/backup/staging/etc/

rsync -aHAX --numeric-ids --relative \
    --exclude-from=excludes-home.txt \
    "$HOME" /mnt/backup/staging/home/

# turn a staged tree into an encrypted archive
tar --xattrs --acls --numeric-owner -C /mnt/backup/staging/etc -cf - . \
    | zstd -19 -T0 \
    | gpg --batch --yes --encrypt --recipient alex.m@controld.com \
          --output /mnt/backup/witchhammer-…/configs/etc.tar.zst.gpg

# same operation, unencrypted (use when destination is already encrypted)
tar --xattrs --acls --numeric-owner -C /mnt/backup/staging/etc -cf - . \
    | zstd -19 -T0 \
    > /mnt/backup/witchhammer-…/configs/etc.tar.zst

# verify a session
cd /mnt/backup/witchhammer-…           # contains SHA256SUMS
sha256sum --check SHA256SUMS
gpg --verify SHA256SUMS.sig SHA256SUMS

# peek inside an archive without decrypting to disk
gpg --decrypt configs/home.tar.zst.gpg | zstd -d | tar -tvf - | less
# unencrypted equivalent:
zstd -d < configs/home.tar.zst | tar -tvf - | less

# extract a single file
gpg --decrypt configs/home.tar.zst.gpg \
    | zstd -d \
    | tar -xf - -C /tmp/restore home/azazel/.bashrc
# unencrypted equivalent:
zstd -d < configs/home.tar.zst \
    | tar -xf - -C /tmp/restore home/azazel/.bashrc

# restore /etc to a scratch dir (never overwrite live config blindly)
mkdir -p /tmp/restore-etc
gpg --decrypt configs/etc.tar.zst.gpg \
    | zstd -d \
    | tar --xattrs --acls --numeric-owner -C /tmp/restore-etc -xf -

# diff staged vs live before applying
rsync --archive --acls --xattrs --hard-links --numeric-ids \
      --dry-run --itemize-changes /tmp/restore-etc/etc/ /etc/ | head -50

# replay packages
sudo apt-get install -y --no-install-recommends $(< apt-manual.txt)
xargs -a flatpak.txt -L1 -I@ sh -c 'set -- @; flatpak install -y "$2" "$1//$3"'
```

## Progress & ETA

The script tries hard not to look frozen during the slow parts:

- **rsync staging** uses `--info=progress2,stats1`, which prints a single
  updating line: `12,345,678   45%  120MB/s  0:00:14` (transferred / pct /
  rate / ETA-for-just-this-section).
- **tar | zstd | gpg pipeline** has no native progress output, so a
  background heartbeat logs `[work] [home] compress+encrypt … still
  running (0h01m30s elapsed)` every 15 seconds. Configure with
  `--heartbeat SEC` (set to 0 to disable).

A pre-flight workload estimate runs before the backup starts:

```
[info] estimating workload (cap: 90s; pass --no-eta to skip)
[info] [eta] etc: 4,521 files, 32.1MiB
[info] [eta] home: 89,213 files, 18.4GiB
[info] [eta] custom: 122 files, 4.2MiB
[info] [eta] total workload: 93,856 files, 18.4GiB
[info] [eta] estimated time: 0h 2m 14s  (assumes ~160 MB/s; coarse estimate)
```

Implementation:
- Each archive section gets a `rsync --dry-run --stats` probe with the
  real exclude rules applied — so the estimate respects `excludes-home.txt`
  and friends.
- Total probe time is hard-capped (default 90s, override with
  `--eta-budget SECONDS`). Hitting the cap turns the estimate into a lower
  bound and tags it "incomplete"; the backup still runs.
- Throughput numbers are coarse — they change with zstd level, encryption
  on/off, and CPU speed. Expect ±2x error in either direction. The point
  is "minutes vs hours", not a precise SLA.
- Skip the whole probe with `--no-eta` if you don't want the upfront delay.

## Snapshot chain (incremental-ish)

`borgbackup` is the eventual upgrade, but until then `--link-dest` gives a
poor person's deduplication: every unchanged file becomes a hardlink to the
previous run's staging tree. Storage cost is roughly the size of changed
files only.

```sh
./backup-system.sh \
    --dest /mnt/backup \
    --link-dest /mnt/backup/witchhammer-2026-05-01T120000Z \
    --gpg-recipient alex.m@controld.com \
    --keep-staging --execute
```

`--keep-staging` is required for the chain to keep working — the next run
needs the staging tree of the previous run as the link target. The
encrypted archive is independent of the staging tree.

## Excludes

`excludes-home.txt` and `excludes-system.txt` are plain rsync filter files.
Edit them freely. The biggest categories already excluded:

- All `.cache/`, `.thumbnails/`, `Trash/`
- Browser disk caches (Firefox, Chrome, Brave, Edge, Vivaldi, Chromium)
- Toolchain caches (`node_modules`, `target/`, `.cargo/registry`,
  `go/pkg/mod/cache`, `.gradle/caches`, `.m2/repository`, etc.)
- Container/VM images
- Steam library / game prefixes
- IDE caches (`.config/JetBrains/*/caches`, `.config/Code/Cache`, …)

Things deliberately **not** excluded:

- `Downloads/` — user data
- `.ssh/` — yes, including private keys (this is your backup)
- `.gnupg/` — same
- `.local/share/keyrings/` — same (commented-out exclude available)
- `.password-store/` — kept

## Threat model / what this is not

- The encryption protects backups in transit and at rest on the destination.
  It does **not** protect against a compromised source machine — the script
  reads everything as the running user (and root for `/etc` if invoked with
  `sudo`).
- `--immutable` (`chattr +i`) raises the bar against accidental
  overwrites, not against a determined root user.
- This is a starting point. `borgbackup`, `restic`, and friends are better
  for retention policies, dedup, and prune. The intent is to graduate to
  one of those once the inventory + restore flow is stable.

## Running with sudo

`/etc` mostly readable as user, but bits like `/etc/shadow`, `/etc/sudoers`,
and `/var/spool/cron` are root-only. To get a complete capture:

```sh
sudo --preserve-env=GNUPGHOME,HOME ./backup-system.sh \
    --dest /mnt/backup \
    --gpg-recipient alex.m@controld.com \
    --execute
```

`--preserve-env=GNUPGHOME,HOME` keeps the user's gpg keyring resolvable.
Otherwise gpg looks in `/root/.gnupg` and won't find your recipient key.
