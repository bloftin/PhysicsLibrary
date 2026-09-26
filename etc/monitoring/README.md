# Physics Library Health Snapshots

This monitor records a small local health snapshot every 30 seconds. It is
intended to preserve evidence around a service stall or reboot without making
requests to any external service.

Each row in `/var/log/physicslibrary/health.tsv` contains the timestamp,
Apache worker counts and scoreboard, one-, five-, and fifteen-minute load,
available memory, free swap, and established HTTPS socket count. The log is
rotated daily and retained for seven days.

## Installation

Run these commands on the server from the repository root:

```bash
sudo install -D -m 0755 etc/monitoring/physicslibrary-health-snapshot \
  /usr/local/sbin/physicslibrary-health-snapshot
sudo install -D -m 0644 etc/systemd/physicslibrary-health-snapshot.service \
  /etc/systemd/system/physicslibrary-health-snapshot.service
sudo install -D -m 0644 etc/systemd/physicslibrary-health-snapshot.timer \
  /etc/systemd/system/physicslibrary-health-snapshot.timer
sudo install -D -m 0644 etc/logrotate.d/physicslibrary-health-snapshot \
  /etc/logrotate.d/physicslibrary-health-snapshot

sudo systemctl daemon-reload
sudo systemctl enable --now physicslibrary-health-snapshot.timer
sudo systemctl start physicslibrary-health-snapshot.service
```

## Verification

```bash
systemctl list-timers physicslibrary-health-snapshot.timer
sudo systemctl status physicslibrary-health-snapshot.timer --no-pager
sudo tail -n 5 /var/log/physicslibrary/health.tsv
```

During or after a suspected stall, inspect the last snapshots with:

```bash
sudo tail -n 120 /var/log/physicslibrary/health.tsv
```
