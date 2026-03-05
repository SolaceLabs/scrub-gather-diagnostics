# scrub-gather-diagnostics

This was written for a customer that had a regulatory requirement to hide specific usernames from any diagnostic files that were sent to vendors.  Solace Support always ask for a "[Gather Diagnostics](https://docs.solace.com/Appliance/Gathering-Appliance-Diagnostics.htm)" file from any broker involved in an issue.  This file contains a multitude of logs and diagnostic files from the broker, and is essential for the Support team to perform their diagnoses.

## Usage

Perform the gather diagnostics action as usual, but ensure the "no-encrypt" options is chosen:
```
solace1025> en
Command auto-completed to:  enable
solace1025# ad
Command auto-completed to:  admin
solace1025(admin)# gather-diagnostics days-of-history 14 no-encrypt
```

Copy the file to your Linux box, or Mac, or WSL on Windows where this script resides.  (if you really don't have a Linux box, all the required utilities are installed on the Solace control plane... you could copy the script onto the broker, placing it in `/usr/sw/jail/logs` and run from there).





