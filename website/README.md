# smpl. privacy policy

Static files for `https://smpl.tnitish.com/privacy-policy`.

## Before deployment

- Confirm that `privacy@tnitish.com` is a working inbox. Replace it in
  `privacy-policy/index.html` if a different address should be used.
- Review the policy whenever the app adds analytics, advertising, accounts,
  developer-operated servers, new permissions, or a new third-party service.

## Deploying

The site is the assets-only Worker `smpl-widgets-privacy-policy`, configured in
`wrangler.jsonc`. Deploy from this directory:

```bash
wrangler deploy
```

The Worker only handles `smpl.tnitish.com/privacy-policy*` and `/app-icon.png`. Every other
path on the subdomain goes to the TestFlight link through the zone redirect rule named
`smpl.widgets`, which excludes those same paths. If you add a page or asset here, add it
to both the Worker routes and that rule, or it will redirect to TestFlight instead.

`.assetsignore` keeps this README and the config files from being uploaded. The
`_headers` file adds a restrictive Content Security Policy and other browser security
headers.
