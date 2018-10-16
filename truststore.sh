#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail


THRESHOLD_IN_DAYS="30"
KEYSTORE=""
PASSWORD=""


usage() {
    echo "Usage: $0 --keystore <keystore> [--password <password>] [--threshold <number of days until expiry>]"
    exit
}

start() {

  #########################################################################################################################################
  ########### Iterate through certs in TrustStore if cert is not in the certificates repository delete it from TrustStore ##############
  #########################################################################################################################################

  for TS_CERT in $(keytool -list -keystore $KEYSTORE $PASSWORD | grep trustedCertEntry | awk -F',' '{print $1}');
  do
    echo $TS_CERT
    CERTNAME=$TS_CERT.cer
    echo "verifying if $CERTNAME is present in the certificates repository"
    if find . $CERTNAME >/dev/null;
    then
      echo "$CERTNAME is present in the certificates repository"
    else
      echo "$CERTNAME is not present in the certificates repository hence removing certificate from the $KEYSTORE"
      keytool -delete -alias $TS_CERT -keystore $KEYSTORE $PASSWORD -noprompt
    fi
  done

  #########################################################################
  ########### Iterate through certs add if cert does not exsists ##########
  #########################################################################
  for CERT in *.cer;
  do
    CERTALIAS=`basename $CERT .cer`
    echo "processing Certificate alias $CERTALIAS"
    if keytool -list -keystore $KEYSTORE $PASSWORD | grep trustedCertEntry | awk '{print $1}' |grep $CERTALIAS >/dev/null
    then
    echo "Certificate with alias $CERTALIAS already exists"
    else
      echo "Certificate with alias $CERTALIAS doesnot exist. Adding it to keystore"
      keytool -import -file $CERT -alias $CERTALIAS -keystore $KEYSTORE $PASSWORD -noprompt
    fi
  done
  ############################################
  ###### Display the validity of certs #######
  ############################################
  CURRENT=`date +%s`
  THRESHOLD=$(($CURRENT + ($THRESHOLD_IN_DAYS*24*60*60)))
  if [ $THRESHOLD -le $CURRENT ]; then
    echo "[ERROR] Invalid date."
    exit 1
  fi
  echo "Looking for certificates inside the keystore $(basename $KEYSTORE) expiring in $THRESHOLD_IN_DAYS day(s)..."
  keytool -list -v -keystore $KEYSTORE $PASSWORD 2>&1 > /dev/null
  if [ $? -gt 0 ]; then echo "Error opening the keystore."; exit 1; fi
  keytool -list -v -keystore "$KEYSTORE"  $PASSWORD | grep Alias | awk -F',' '{print $1}' | sed 's/Alias name: //' | while read ALIAS
  do
    # Iterate through all the certificate alias
    UNTIL=`keytool -list -v -keystore "$KEYSTORE" $PASSWORD -alias "$ALIAS" | grep Valid | perl -ne 'if(/until: (.*?)\n/) { print "$1\n"; }'`
    UNTIL_SECONDS=`date -d "$UNTIL" +%s`
    REMAINING_DAYS=$(( ($UNTIL_SECONDS -  $(date +%s)) / 60 / 60 / 24 ))
    if [ $THRESHOLD -le $UNTIL_SECONDS ]; then
      echo "[OK] Certificate '$ALIAS' expires in '$UNTIL' ($REMAINING_DAYS day(s) remaining)."
    elif [ $REMAINING_DAYS -le 0 ]; then
      echo "[CRITICAL] Certificate $ALIAS has already expired."
    else
      echo "[WARNING] Certificate '$ALIAS' expires in '$UNTIL' ($REMAINING_DAYS day(s) remaining)."
    fi
  done
  echo "Finished execution"

}

while [ $# -gt 0 ]
do
  case "$1" in
    --password)
    if [ -n "$2" ]; then PASSWORD=" -storepass $2"; else echo "Invalid password"; exit 1; fi
    shift 2;;
    --keystore)
    if [ ! -f "$2" ]; then echo "Keystore not found: $1"; exit 1; else echo "Second Argument is $2"; KEYSTORE=$2; fi
    shift 2;;
    --threshold)
    if [[ $2 =~ ^[0-9]+$ ]]; then THRESHOLD_IN_DAYS=$2; else echo "Invalid threshold"; exit 1; fi
    ;;
    *)
    echo "Invalid Paramaeter"
    exit -1;
  esac
done

if [ -n "$KEYSTORE" ]
then
  start
else
  usage
fi
