# Simple Antivirus Daemon

A shell-based antivirus daemon that polls a directory, quarantines malicious files, plus an interactive restore tool, a cron version, and a persistent whitelist.

## 1. Overview and folder hierarchy

```
lab1/
├── antivirusd.sh        # Part 1: polling daemon (scan + quarantine)
├── restore.sh           # Part 2: interactive restore/delete tool
├── antivirus-cron.sh    # Bonus 1: single-pass version for cron
├── Makefile             # Part 3: targets + pre-build step
├── README.md
├── whitelist.txt        # Bonus 2: created at runtime (safe filenames)
├── directory-info.last  # created at runtime (previous snapshot)
├── directory-info.new   # created at runtime (current snapshot)
├── watched/             # default monitored dir (files only)
└── malicious_dir/       # quarantine dir (created by `make`)
```

How it works: every `interval-secs` the daemon runs `ls -l dir > directory-info.new` and diffs it against `directory-info.last`. On the first run (no `.last`) it scans immediately. If they differ, it scans `dir`, then copies `.new` over `.last`. For each malicious file it prints `<file> is malicious and it is DELETED`, copies it into `malicious_dir`, and deletes the original.

## 2. Prerequisites (Ubuntu)

```bash
sudo apt update
sudo apt install -y bash make coreutils diffutils grep cron
```
(Most are preinstalled; `make` and `cron` are the usual missing ones.)

## 3. Running

Antivirus (via Makefile, creates `malicious_dir` first):
```bash
chmod +x antivirusd.sh restore.sh antivirus-cron.sh
make                               # uses DIR=watched MALICIOUS_DIR=malicious_dir INTERVAL=5
make DIR=/path/to/dir INTERVAL=10
```
Or directly:
```bash
./antivirusd.sh watched malicious_dir 5
```
Restore tool (do NOT run at the same time as the daemon):
```bash
make restore
# or
./restore.sh watched malicious_dir
```
In the restore tool: pick a file by number, then `1` restore (false positive), `2` permanently delete, `3` leave it and go back. If quarantine is empty it prints `No malicious files to review.`

## 4. Flagged lists

Defined at the top of `antivirusd.sh` (and duplicated at the top of `antivirus-cron.sh`):
- `FLAGGED_EXTENSIONS=(.exe .bat .vbs .scr .ps1)`
- `FLAGGED_KEYWORDS=(virus trojan malware worm ransomware)` (case-insensitive content match)

## Bonus 1: Cron job

Prerequisites: cron installed and running (`sudo systemctl enable --now cron`), scripts executable (`chmod +x antivirus-cron.sh`), the monitored directory exists, and you know the absolute paths.

1. `crontab -e`
2. Add (cron has a 1-minute resolution, so `antivirus-cron.sh` itself does `sleep 23` so the scan happens at second 23):
   ```
   * * * * * /home/maro/9223-OS-Labs/lab1/antivirus-cron.sh /home/maro/9223-OS-Labs/lab1/watched /home/maro/9223-OS-Labs/lab1/malicious_dir >> /tmp/antivirus-cron.log 2>&1
   ```
3. Verify with `crontab -l` and `tail -f /tmp/antivirus-cron.log`.

**Cron expression for every 3rd Friday of the month at 12:31 am:**
```
31 0 15-21 * * [ "$(date +\%u)" -eq 5 ] && /home/maro/9223-OS-Labs/lab1/antivirus-cron.sh /home/maro/9223-OS-Labs/lab1/watched /home/maro/9223-OS-Labs/lab1/malicious_dir
```
The 3rd Friday always falls on days 15–21. Cron ORs day-of-month and day-of-week when both are set, so the weekday is checked in the command (`%` must be escaped as `\%` in crontab).

## Bonus 2: Whitelist

- **Adding:** when you choose option 1 (restore) in `restore.sh`, the file's name is appended to `whitelist.txt` (in the same folder as the scripts) if not already present.
- **Checking:** during every scan, before testing extension/keywords, the daemon (and the cron script) runs `grep -qxF "<filename>" whitelist.txt`; an exact match means the file is skipped.
- **Persistence:** it is a plain file on disk, so it survives stopping/restarting the daemon. Delete a line from `whitelist.txt` to un-trust a file.
