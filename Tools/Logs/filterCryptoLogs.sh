#!/bin/sh

# Filter Riot logs to extract only logs related to end-to-end encryption.
# The output is colorised according to the cryto sub module.
#
# Usage:
# ./filterCryptoLogs.sh console.log

FILES=$1

if [ ! -n "$FILES" ]; then
    FILES="*"
fi 

grep -iE 'crypto|MXDevice|olm|error|MXKey|KeyRequest' $FILES \
    | grep -viE 'MXJSONModels|MXOlmSessionResult|MXRealmCryptoStore|NSCocoaErrorDomain|olm_keys_not_sent_error' \
    | awk '{
        # Errors in red (I failed to make a gsub case insensitive)
        gsub(".*error.*", "\033[0;31m&\033[0m");
        gsub(".*Error.*", "\033[0;31m&\033[0m");
        gsub(".*ERROR.*", "\033[0;31m&\033[0m");
    
        # Isolate each encryption of a message
        gsub(".*\\[MXRoom] sendEventOfType\\(MXCrypto\\)\\: Encrypting event.*",
         "\n\n\n\n++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n&");
        gsub(".*\\[MXRoom] sendEventOfType\\(MXCrypto\\)\\: Send event.*",
         "&\n----------------------------------------------------------------------------------------------------------------\n\n\n\n");
        gsub(".*\\[MXRoom] sendEventOfType\\(MXCrypto\\)\\: Cannot encrypt.*",
         "&\n----------------------------------------------------------------------------------------------------------------\n\n\n\n");
    
        gsub("\\[MXCrypto\\]", "\033[0;32m&\033[0m");
        gsub("\\[MXOlmDevice\\]", "\033[0;33m&\033[0m");
    
        gsub("\\[MXMegolmEncryption\\]", "\033[0;36m&\033[0m");
    
        gsub("\\[MXOlmInboundGroupSession\\]", "\033[1;34m&\033[0m");
        gsub("\\[MXMegolmDecryption\\]", "\033[0;34m&\033[0m");

        gsub("\\[MXOlmDecryption\\]", "\033[0;34m&\033[0m");
    
        gsub("\\[MXDeviceList\\]", "\033[0;36m&\033[0m");
        gsub("\\[MXDeviceListOperationsPool\\]", "\033[1;36m&\033[0m");
    
        gsub("\\[MXKey\\]", "\033[1;35m&\033[0m");
        gsub("\\[MXKeyBackup\\]", "\033[1;35m&\033[0m");
        gsub("\\[MXKeyBackupPassword\\]", "\033[1;35m&\033[0m");
        gsub("\\[MXMegolmExportEncryption\\]", "\033[1;35m&\033[0m");
        gsub("\\[MXKeyBackupPassword\\]", "\033[1;35m&\033[0m");
    
        gsub("\\[MXOutgoingRoomKeyRequestManager\\]", "\033[1;35m&\033[0m");
        gsub("\\[MXIncomingRoomKeyRequestManager\\]", "\033[1;34m&\033[0m");
    
        gsub("\\[MXDeviceVerificationTransaction\\]", "\033[0;36m&\033[0m");
        gsub("\\[MXKeyVerification\\]", "\033[0;36m&\033[0m");
    
        gsub("\\[MXRealmCryptoStore\\]", "\033[0;37m&\033[0m");
    
        print 
    }' 
