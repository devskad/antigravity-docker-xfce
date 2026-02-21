#!/with-contenv bash

# 1. Define variables
TARGET_USER="abc"
# Most LSIO containers map the abc user's home to /config
USER_HOME="/config" 
GPG_DIR="$USER_HOME/.gnupg"
BATCH_FILE="/tmp/gpg-params.txt"

# # Don't do this step. Docker will copy a file into $BATCH_FILE
# # 2. Check if the abc user already has a keyring
# # We check for 'pubring.kbx', which is the standard GPG database file
# if [ ! -f "$GPG_DIR/pubring.kbx" ]; then
#     echo "[First Boot] No GPG keyring found for $TARGET_USER. Generating now..."

#     # 3. Create the temporary batch file
#     cat <<EOF > "$BATCH_FILE"
# %no-protection
# Key-Type: RSA
# Key-Length: 4096
# Name-Real: Container Admin
# Name-Email: admin@container.local
# Expire-Date: 0
# %commit
# EOF

    # 4. Execute the generation AS the abc user
    # This ensures all folders and files are owned by abc, not root
    #   Get the Fingerprint
    FPR=$(su - $TARGET_USER -c "gpg --list-keys --with-colons" | awk -F: '/^fpr:/ { print $10; exit }')
    su - $TARGET_USER -c "gpg --batch --generate-key $BATCH_FILE"
    # Update fingerprint in key to make gpg and kwalletmanager work
    echo -e "5\ny\n" | su - $TARGET_USER -c "gpg --batch --command-fd 0 --edit-key $FPR trust"

    # 5. Cleanup the sensitive batch file
    rm "$BATCH_FILE"
    
    echo "[First Boot] GPG key generation for $TARGET_USER complete."
else
    echo "GPG keyring for $TARGET_USER already exists. Skipping."
fi