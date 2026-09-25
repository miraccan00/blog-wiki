# "No SSH" in practice: what you type instead

Every one of these goes over the Talos API (gRPC, mTLS, port 50000). `--nodes` picks the
machine; without `--nodes` the command goes to the default node in your talosconfig.
All of them were run against the lab in this folder (talosctl 1.13).

| What you used to do over SSH | talosctl |
|---|---|
| `journalctl -u kubelet -f` | `talosctl logs kubelet -f` |
| `dmesg` | `talosctl dmesg` |
| `systemctl status` | `talosctl services` |
| `systemctl restart containerd` | `talosctl service containerd restart` |
| `top` / `htop` | `talosctl dashboard` |
| `cat /etc/hosts`, `cat /proc/sys/...` | `talosctl read /etc/hosts` |
| `ls /var/lib` | `talosctl list /var/lib` (`ls` works too) |
| `df -h` | `talosctl mounts` |
| `du -sh /var/*` | `talosctl usage /var --depth 1` |
| `ss -tulpn` | `talosctl netstat -l` |
| `ip addr` | `talosctl get addresses` |
| `ps aux` | `talosctl processes` |
| `crictl ps` | `talosctl containers -k` |
| `vim /etc/kubernetes/...` | there is no file to edit: `talosctl patch mc` / `talosctl edit mc` |
| `reboot` | `talosctl reboot` |
| `shutdown -h now` | `talosctl shutdown` |
| `sudo -i`, `bash` | does not exist |
| `scp node:/var/log/x .` | `talosctl copy /var/log/x .` (read-only paths) |
| "who has root on this box?" | `talosctl config info` (role is in the client cert: `os:admin`, `os:operator`, `os:reader`) |

The last two rows are the point. On a Talos node there is no user, no shell, no package
manager and no writable root filesystem. What can be changed is the machine config, and the
API is the only door to it, so the audit log of "who did what to this node" is the API log.
