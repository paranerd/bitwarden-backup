#!/usr/bin/bash

# Fail the script as soon as an invalid password has been entered
set -e

export EXPORT_PATH=${EXPORT_PATH:=.}
export EXPORT_NAME=bitwarden_encrypted_export_$(date "+%Y%m%d%H%M%S")

# Prompt for Bitwarden password
echo -n "Enter your Bitwarden password: "
read -s master_password
export BW_PASSWORD="$master_password"
echo

# Prompt for encryption password
echo -n "Enter a password to encrypt your vault (or press ENTER to use Master Password): "
read -s password1
password1=${password1:-$BW_PASSWORD}
echo

# If password != Master Password -> verify
if [[ "$password1" != "$BW_PASSWORD" ]]
then
    echo -n "Enter the same password for verification: "
    read -s password2
    echo

    if [[ $password1 != $password2 ]]
    then
        echo "ERROR: The passwords did not match."
        echo
        exit 1
    else
        echo "Password verified. Be sure to save your password in a safe place!"
        echo
    fi
fi

# Login if not already authenticated
if [[ $(bw status | jq -r .status) == "unauthenticated" ]]
then
    if [ -n "${BW_CLIENTID}" ] && [ -n "${BW_CLIENTSECRET}" ]
    then
      echo "Logging in with API Key..."
      bw login --apikey
    elif [ -n "${BW_CLIENTID_ENC}" ] && [ -n "${BW_CLIENTSECRET_ENC}" ]
    then
      export BW_CLIENTID=$(echo $BW_CLIENTID_ENC | openssl enc -base64 -d -aes-256-cbc -salt -pass pass:$BW_PASSWORD -pbkdf2)
      export BW_CLIENTSECRET=$(echo $BW_CLIENTSECRET_ENC | openssl enc -base64 -d -aes-256-cbc -salt -pass pass:$BW_PASSWORD -pbkdf2)

      echo "Logging in with API Key..."
      bw login --apikey
    else
      echo "Logging in with username and password..."
      bw login $BW_EMAIL $BW_PASSWORD --method 0 # --quiet
    fi
fi
if [[ $(bw status | jq -r .status) == "unauthenticated" ]]
then
    echo "ERROR: Login failed."
    echo
    exit 1
fi

# Store session key
export BW_SESSION=$(bw unlock --passwordenv BW_PASSWORD --raw)

# Verify that unlock succeeded
if [[ $BW_SESSION == "" ]]
then
    echo "ERROR: Unlock failed."
    echo
    exit 1
else
    echo "Unlock successful."
    echo
fi

# Sync to get latest data
bw sync

# Export
if [[ ! -d "$EXPORT_PATH" ]]
then
    echo "ERROR: Export path ($EXPORT_PATH) does not exist."
    echo
    exit 1
fi

echo "Exporting vault..."
bw export --format encrypted_json --password $password1 --output $EXPORT_PATH/$EXPORT_NAME/bitwarden.json

# Export attachments
if [[ $(bw list items | jq -r '.[] | select(.attachments != null)') != "" ]]
then
    echo
    echo "Exporting attachments..."
    bash <(bw list items | jq -r '.[] 
     | select(.attachments != null) 
     | . as $parent | .attachments[] 
     | "bw get attachment \(.id) --itemid \($parent.id) --output \"${EXPORT_PATH}/${EXPORT_NAME}/attachments/\($parent.id)/\(.fileName)\""')
else
    echo
    echo "No attachments to export."
fi

echo "Locking vault..."
bw lock
echo

# Create an archive with all exported data
echo "Archiving export..."
tar czf ${EXPORT_PATH}/${EXPORT_NAME}.tar.gz -C ${EXPORT_PATH}/ ${EXPORT_NAME}
rm -rf ${EXPORT_PATH}/${EXPORT_NAME}

# Encrypt the archive
echo "Encrypting export..."
gpg --batch --passphrase $password1 --symmetric --cipher-algo AES256 ${EXPORT_PATH}/${EXPORT_NAME}.tar.gz

# Delete unencrypted data
echo "Cleaning up..."
rm ${EXPORT_PATH}/${EXPORT_NAME}.tar.gz

echo
echo "Export complete."
