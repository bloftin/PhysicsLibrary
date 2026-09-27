# Physics Library Health Snapshots

This monitor records a small local health snapshot every 30 seconds. It is
intended to preserve evidence around a service stall or reboot without making
requests to any external service.

Each row in `/var/log/physicslibrary/health.tsv` contains the timestamp,
Apache worker counts and scoreboard, one-, five-, and fifteen-minute load,
available memory, free swap, and established HTTPS socket count. When available
memory falls below 256 MiB, the monitor also appends the largest resident
processes to `/var/log/physicslibrary/memory-pressure.log`. When load reaches
one runnable task or the Apache pool is saturated, it records the highest-CPU
processes and active TeX/render commands in
`/var/log/physicslibrary/cpu-pressure.log`. The logs are rotated daily and
retained for seven days.

For per-article PID, timing, and memory breadcrumbs inside the render pipeline,
see [Render-stage logging](render-stage-logging.md). It complements these
host-level snapshots and requires no additional scheduled job.

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
sudo tail -n 80 /var/log/physicslibrary/memory-pressure.log
sudo tail -n 80 /var/log/physicslibrary/cpu-pressure.log
```

Set `PHYSICSLIBRARY_MEMORY_SNAPSHOT_THRESHOLD_KB` in the service environment
to use a threshold other than the default 262144 KiB.
Set `PHYSICSLIBRARY_CPU_SNAPSHOT_LOAD_THRESHOLD` to change the default
one-runnable-task CPU capture threshold.
