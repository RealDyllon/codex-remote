# Codex Remote Local Maintenance

This MacBook is running the local Codex Remote relay, bridge, Codex runtime, and iOS development build path.

## Current local values

- Repo root: `/Users/dyllon/Developer/codex-remote`
- Tailscale IP: `100.107.153.95`
- Relay port: `9000`
- Relay URL: `ws://100.107.153.95:9000/relay`
- Health URL: `http://100.107.153.95:9000/health`
- Relay LaunchAgent: `/Users/dyllon/Library/LaunchAgents/com.codexremote.tailnet-relay.plist`
- Relay stdout log: `/Users/dyllon/Library/Logs/codex-remote-tailnet-relay/relay.out.log`
- Relay stderr log: `/Users/dyllon/Library/Logs/codex-remote-tailnet-relay/relay.err.log`
- iOS local bundle ID: `com.dyllon.codex-remote.local`
- iOS app path: `/Users/dyllon/Developer/codex-remote/.derivedData-codex-remote/Build/Products/Debug-iphoneos/CodexMobile.app`

## Check relay health

```bash
curl -fsS "http://100.107.153.95:9000/health"
```

Expected:

```json
{"ok":true}
```

## After reboot

The relay should start automatically when you log in because it is installed as a LaunchAgent.

Check the relay:

```bash
curl -fsS "http://100.107.153.95:9000/health"
```

If the relay is not healthy, restart it:

```bash
launchctl kickstart -k gui/$(id -u)/com.codexremote.tailnet-relay
```

Start or refresh the bridge server:

```bash
cd "/Users/dyllon/Developer/codex-remote/codex-remote-bridge"
CODEX_REMOTE_RELAY="ws://100.107.153.95:9000/relay" node ./bin/codex-remote.js up
```

Check bridge status:

```bash
cd "/Users/dyllon/Developer/codex-remote/codex-remote-bridge"
CODEX_REMOTE_RELAY="ws://100.107.153.95:9000/relay" node ./bin/codex-remote.js status
```

## Relay restart

```bash
launchctl kickstart -k gui/$(id -u)/com.codexremote.tailnet-relay
```

## Relay stop

```bash
launchctl bootout gui/$(id -u) "$HOME/Library/LaunchAgents/com.codexremote.tailnet-relay.plist"
```

## Relay logs

```bash
tail -f "$HOME/Library/Logs/codex-remote-tailnet-relay/relay.out.log"
```

```bash
tail -f "$HOME/Library/Logs/codex-remote-tailnet-relay/relay.err.log"
```

## Bridge start

```bash
cd "/Users/dyllon/Developer/codex-remote/codex-remote-bridge"
CODEX_REMOTE_RELAY="ws://100.107.153.95:9000/relay" node ./bin/codex-remote.js up
```

## Bridge status

```bash
cd "/Users/dyllon/Developer/codex-remote/codex-remote-bridge"
CODEX_REMOTE_RELAY="ws://100.107.153.95:9000/relay" node ./bin/codex-remote.js status
```

## Fresh pairing

```bash
cd "/Users/dyllon/Developer/codex-remote/codex-remote-bridge"
CODEX_REMOTE_RELAY="ws://100.107.153.95:9000/relay" node ./bin/codex-remote.js reset-pairing
CODEX_REMOTE_RELAY="ws://100.107.153.95:9000/relay" node ./bin/codex-remote.js up
```

Scan the printed QR from inside the Codex Remote app onboarding or pairing flow, not with the iPhone Camera app.

## iPhone connectivity check

On the iPhone, keep Tailscale enabled and open:

```text
http://100.107.153.95:9000/health
```

Expected:

```json
{"ok":true}
```
