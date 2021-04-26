# Bash Utilities

A set of useful bash utilities.

## Directory Structure

```bash

bash
  + commons         Common Utilities
  + confluence      Confluence Utilities
  + eclipse         Eclipse Utilities
  + git             Git Utilities
  + sapcc           SAP Commerce Cloud Utilties

```

## FASTLane Spartacus Setup

CLONE THIS REPO

```bash
cd ~
git clone git@bitbucket.org:jtday/bash.git
```

RUN SETUP SCRIPT

One click setup.  PLEASE NOTE:  you need to save any work, please this script will delete the `/opt/lyonscg/sapcc-rlp`
directory and clone the `sapcc-rlp` repo

```bash
cd ~/bash/sapcc/fastlane
./fastlane_reset.sh 2>&1 | tee fastlane_reset.log
```

MONITOR PROCESS OF SETUP SCRIPT

```bash
cd ~/bash/sapcc/fastlane
grep 'fastlane_reset' fastlane_reset.log
```

PATCH PROCESS FOR WAREHOUSES

* run impex
* run HAC update - make sure to check "Toggle all" checkbox

```bash
INSERT_UPDATE Warehouse;code[unique=true];name;vendor(code)[default=default, forceWrite=true];default[default=true, forceWrite=true]
;default;Default Warehouse;
;warehouse_s;Warehouse South;electro;
;warehouse_e;Warehouse East;electro;
;warehouse_w;Warehouse West;electro;
;warehouse_n;Warehouse North;electro;
```

CHECK FOR ISSUES ON HYBRIS STARTUP

Assumes you have done "Clone this repo"

```bash
cd /opt/lyonscg/sapcc-rlp/hybris-suite/hybris/log/tomcat
rm *.log

cd /opt/lyonscg/sapcc-rlp/hybris-suite/hybris/bin/platform
. ./setantenv.sh
./hybrisserver.sh 

# In another terminal

tail -f $(/bin/ls -1t /opt/lyonscg/sapcc-rlp/hybris-suite/hybris/log/tomcat/console-* | /bin/sed q) | grep -i 'error'

# OR, if you don't want to use tail, you can also wait for server to startup and then "grep -i 'error' <log file>"

# wait for server to finish startup
```

TEST OCC
```bash
curl -kX GET "https://localhost:9002/rest/v2/basesites?fields=DEFAULT" -H  "accept: application/json"
```
