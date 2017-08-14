# bitino
BILLmanager Ticket Notifier

## Author's notes

Since I got problems when trying to start BiTiNo as a systemd user service, I've found a bit easier solution, that works well for me:
```bash
echo "${BITINO_PATH}/bitinod start" >> "${HOME}/.xprofile"
```

This will make BiTiNo start together with your X11 session (won't work on Wayland!).
