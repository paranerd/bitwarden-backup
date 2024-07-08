# Bitwarden Backup

This is a helper tool for backing up a Bitwarden Vault **including** attachments (which are not included in the built-in export).

It uses the official Bitwarden CLI.

The functionality is deliberately kept to a minimum. Here's what it will do:

1. Log in to the Bitwarden Account
1. Unlock it
1. Download all vault items as encrypted JSON
1. Download all attachments
1. Archive using TAR
1. Encrypt using GPG

## Usage

```bash
sudo docker run -it -e BW_EMAIL="your@mail.com" -v "/host/path/to/exports:/app/exports" paranerd/bitwarden-backup
```

You will be prompted for your Master Password, your 2FA code (if applicable) as well as the password you want your export to be encrypted with.
