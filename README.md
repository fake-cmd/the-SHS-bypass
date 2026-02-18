# Localhost Proxy

This repo now includes a small HTTP proxy you can run on localhost.

## Run

```bash
python localhost_proxy.py --host 127.0.0.1 --port 8080
```

Then configure your app/browser/tool to use:

- **Host:** `127.0.0.1`
- **Port:** `8080`

## Notes

- Supports regular HTTP methods (`GET`, `POST`, `PUT`, `PATCH`, `DELETE`, etc.).
- `CONNECT` tunneling (HTTPS proxy mode) is not implemented in this minimal version.
