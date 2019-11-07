#!/bin/sh

# Filter Riot logs to extract only logs related to end-to-end encryption.
# The output is colorised according to the cryto sub module.
#
# Usage:
# ./filterStartupLogs.sh console.log

FILES=$1

if [ ! -n "$FILES" ]; then
    FILES="*"
fi 

grep -iE 'AppDelegate|crypto|MXSession|\[MXKAccount\]|[0-9]+ms|\[MXHTTPClient\]\ \#' $FILES \
    | grep -viE 'MXJSONModels|MXOlmSessionResult|MXRealmCryptoStore|NSCocoaErrorDomain|olm_keys_not_sent_error|decryptEvent:\ Error|\[MXFileStore\ commit\]' \
    | awk '{
        # Errors in red (I failed to make a gsub case insensitive)
        gsub(".*error.*", "\033[0;31m&\033[0m");
        gsub(".*Error.*", "\033[0;31m&\033[0m");
        gsub(".*ERROR.*", "\033[0;31m&\033[0m");
        
        gsub("\\[AppDelegate\\]", "\033[0;33m&\033[0m");
        
        gsub("\\[MXSession\\]", "\033[1;35m&\033[0m");
        gsub("\\[MXCrypto\\]", "\033[0;36m&\033[0m");
    
        gsub("\\[MXRoom\\]", "\033[0;36m&\033[0m");
        
        gsub("\\[MXHTTPClient\\]", "\033[0;34m&\033[0m");
        

        gsub("\\[MXKAccount\\]", "\033[0;32m&\033[0m");
        
        gsub("\[0-9\]+ms", "\033[0;33m&\033[0m");
    
        gsub(".*The session is ready.*", "&\n----\n\n\n\n");
         
        print 
    }' 
