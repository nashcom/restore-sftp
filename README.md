# restore-sftp

A minimal, secure SFTP container for file restore operations in Kubernetes and Docker environments.

The container runs an OpenSSH SFTP server on port **2222** with a chroot jail at `/sftp`.
File systems to be accessed are mounted into `/sftp` at runtime — the container itself carries no data.
Authentication is public-key only (Ed25519); password authentication is disabled.

---

## How It Works

- The `restore` user (UID 1000) is locked to `/sftp` via `ChrootDirectory`
- `ForceCommand internal-sftp` ensures only SFTP operations are possible — no shell, no port forwarding, no TTY
- The SSH host key and the authorized client key are injected at startup via environment variables or Docker/Kubernetes secrets
- Any number of directories can be mounted under `/sftp` and will be immediately accessible to the SFTP client

---

## Building

```bash
./build.sh              # Alpine-based image  (tagged restore-sftp:latest)
./build.sh -wolfi       # Wolfi/Chainguard image (tagged restore-sftp:wolfi)
```

| Option | Description |
|--------|-------------|
| `-wolfi` | Use `cgr.dev/chainguard/wolfi-base` instead of Alpine |
| `-h` / `--help` | Show usage |

---

## Configuration

### Environment Variables

| Variable | Description |
|----------|-------------|
| `AUTHORIZED_KEY` | SSH public key string allowed to connect (e.g. contents of `~/.ssh/id_ed25519.pub`) |
| `HOST_KEY_B64` | Base64-encoded Ed25519 SSH **private** host key (use `base64 -w0 <keyfile>`) |

### Secrets (Docker secrets / Kubernetes secrets)

As an alternative to environment variables, keys can be provided as mounted secrets:

| Secret path | Description |
|-------------|-------------|
| `/run/secrets/authorized_key` | SSH public key (fallback if `AUTHORIZED_KEY` is not set) |
| `/run/secrets/ssh_host_ed25519_key` | SSH private host key (fallback if `HOST_KEY_B64` is not set) |

**Priority order for host key:** `HOST_KEY_B64` → `/run/secrets/ssh_host_ed25519_key` → auto-generated at startup

**Priority order for authorized key:** `AUTHORIZED_KEY` → `/run/secrets/authorized_key`

> If no host key is provided by either method, a new key is generated at container startup. The public key is printed to the container log so it can be used to populate `known_hosts`.

### Volume Mounts

Mount any directory that should be accessible via SFTP under `/sftp`:

```
/sftp/<path>   →  sftp://restore@host:2222/<path>
```

The chroot jail is at `/sftp`, so the SFTP client path is relative to that root.

Example: a volume mounted at `/sftp/data` is accessed as `/data` in the SFTP session.

---

## Running (Docker)

Generate a host key and start the container:

```bash
ssh-keygen -t ed25519 -N '' -C RestoreSFTP -f restore_ssh_host_ed25519_key

docker run -d \
  --name restore-sftp \
  -e AUTHORIZED_KEY="$(cat ~/.ssh/id_ed25519.pub)" \
  -e HOST_KEY_B64="$(base64 -w0 restore_ssh_host_ed25519_key)" \
  -p 2222:2222 \
  -v /path/to/data:/sftp/data \
  restore-sftp
```

See `run.sh` for a self-contained example including host key generation and volume mounts.

---

## Running in Kubernetes

Store the host key and authorized key as Kubernetes secrets:

```bash
kubectl create secret generic restore-sftp-keys \
  --from-file=ssh_host_ed25519_key=./restore_ssh_host_ed25519_key \
  --from-literal=authorized_key="$(cat ~/.ssh/id_ed25519.pub)"
```

Example pod manifest:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: restore-sftp
spec:
  containers:
    - name: restore-sftp
      image: restore-sftp:latest
      ports:
        - containerPort: 2222
      volumeMounts:
        - name: sftp-keys
          mountPath: /run/secrets
          readOnly: true
        - name: restore-data
          mountPath: /sftp/data
  volumes:
    - name: sftp-keys
      secret:
        secretName: restore-sftp-keys
    - name: restore-data
      persistentVolumeClaim:
        claimName: my-pvc
```

Expose the pod with a `NodePort` or `LoadBalancer` service on port 2222, or use `kubectl port-forward` for ad-hoc access:

```bash
kubectl port-forward pod/restore-sftp 2222:2222
```

---

## Connecting

```bash
sftp -P 2222 restore@<host>
```

For scripted use with a known host key:

```bash
echo "[<host>]:2222 $(ssh-keygen -y -f restore_ssh_host_ed25519_key)" > known_hosts
sftp -o UserKnownHostsFile=known_hosts -P 2222 restore@<host>:/data/file.tar ./file.tar
```

See `restore_test.sh` for a working example.

---

## Security

- Ed25519 public key authentication only — no passwords
- `PermitRootLogin no`
- `AllowTcpForwarding no`, `AllowAgentForwarding no`, `PermitTunnel no`, `X11Forwarding no`
- `PermitTTY no` — no interactive shell access
- `ChrootDirectory /sftp` — client cannot traverse outside the mount root
- `ForceCommand internal-sftp` — no arbitrary command execution
- Protocol 2 only
- Minimal image footprint (Alpine or Wolfi base)
