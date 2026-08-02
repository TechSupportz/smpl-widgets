# smpl. privacy policy

Static files for `https://smpl.tnitish.com/privacy-policy`.

## Before deployment

- Confirm that `privacy@tnitish.com` is a working inbox. Replace it in
  `privacy-policy/index.html` if a different address should be used.
- Review the policy whenever the app adds analytics, advertising, accounts,
  developer-operated servers, new permissions, or a new third-party service.

## Cloudflare Pages

For a Git-connected Pages project:

- Framework preset: `None`
- Build command: leave blank
- Build output directory: `website`

For Direct Upload, upload the contents of this `website` directory.

The `_redirects` file routes the site root and the non-trailing-slash policy URL to
`/privacy-policy/`. The `_headers` file adds a restrictive Content Security Policy and
other browser security headers.
