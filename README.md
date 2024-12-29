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

## Login with Client ID and Client Secret

### Plain text

If Client ID and Client Secret are stored in the environment variables `BW_CLIENTID` and `BW_CLIENTSECRET`, respectively, you will only be prompted for the Master Password. No input of a 2FA code is required.

### Encrypted

If Client ID and Client Secret shall not be stored in plain text, use the following commands to encrypt both values with the Master Password, then store them in the `BW_CLIENTID_ENC` and `BW_CLIENTSECRET_ENC` variables, respectively.

**Encrypt Client ID:**

```bash
echo $BW_CLIENTID | openssl enc -base64 -e -aes-256-cbc -salt -pass pass:$BW_MASTER_PASSWORD -pbkdf2
```

**Encrypt Client Secret:**

```bash
echo $BW_CLIENTSECRET | openssl enc -base64 -e -aes-256-cbc -salt -pass pass:$BW_MASTER_PASSWORD -pbkdf2
```

## Recover

**Important:** This tool at its current state is meant for backup ONLY. Meaning it doesn't include an easy way for re-import.

To recover / take a look at the export use the following commands:

```bash
gpg --output vault.tar.gz --decrypt bw-export-*.tar.gz.gpg
```

```bash
tar -xf vault.tar.gz
```

```bash
chmod -R 755 bw-export-*
```
