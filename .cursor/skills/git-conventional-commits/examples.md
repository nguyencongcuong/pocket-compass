# Conventional commit examples

## Single-line commits

```bash
git add lib/compass/compass_screen.dart
git commit -m "feat(compass): request location before subscribing to heading"
git push
```

```bash
git commit -m "fix(android): add fine location permission for compass plugin"
```

```bash
git commit -m "docs(readme): describe physical device testing for magnetometer"
```

## With body (multiple `-m`)

```bash
git commit -m "refactor(compass): extract heading smoother" -m "Isolate wrap-safe exponential filter for reuse and tests."
```

## Breaking change (footer)

```bash
git commit -m "feat(api)!: rename auth token header" -m "Clients must send X-Auth-Token instead of Authorization Bearer for device flow." -m "BREAKING CHANGE: header name changed; update mobile app before deploy."
```

## First push of branch

```bash
git push -u origin feature/compass-ui
```
