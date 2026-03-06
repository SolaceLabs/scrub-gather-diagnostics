# scrub-gather-diagnostics

This was written for a customer that had a regulatory requirement to hide specific usernames from any diagnostic files that were sent to vendors.  Solace Support always ask for a "[Gather Diagnostics](https://docs.solace.com/Appliance/Gathering-Appliance-Diagnostics.htm)" file from any broker involved in an issue.  This "GD" tarball contains a multitude of logs and diagnostic files from the broker, and is essential for the Support team to perform their diagnoses.

![gather-diagnostics diff screenshot before and after scrub](./screenshot.png)


## Usage

Perform the gather diagnostics action as usual, but ensure the "**no-encrypt**" options is chosen:
```
solace1025> enable
solace1025# admin
solace1025(admin)# gather-diagnostics days-of-history 14 no-encrypt

Starting to copy files...
<SNIP>
Finished creating encrypted tarball...

Diagnostics saved in: logs/gather-diagnostics_14d_solace1025_2026-02-22T23.21.18.tgz

solace1025(admin)#
```

Copy the generated file to your Linux box, or Mac, or WSL on Windows where this script resides.



### User File

By default, the script loads in the text file `known_users.txt`, and searches all the files within the gather diagnostics tarball for those names and obfuscates them.  Please build your own list from LDAP or Active Directory or wherever.  Feel free to edit the name of the user file at the top of the script.

In my testing while building the script, it worked fine for 5000 usernames, although a bit slower.  If you have more usernames than that, or the script is breaking, please raise a GH Issue: there are some known improvements that could be made in this area (improved regex, pre-regex hash check for performance, etc.).  There's also [a little script](test/find-admin-usernames.sh) inside directory `test/` that you can use to extract _some_ of the usernames from your log files for testing.


### Running

Run by passing the name of the gather diagnostics tarball to the script.  At the end, you'll have an option to encrypt the scrubbed version using `gpg`.

```
$ ./gd-scrub.sh gather-diagnostics_14d_solace1025_2026-02-22T23.21.18.tgz

 ┌──────────────────────────────────────────────────╖
 │ Solace gather-diagnostics username scrubber v1.0 ║
 │       - Aaron Lee | ©2026 | aaron.lee@solace.com ║
 ╘══════════════════════════════════════════════════╝

Loading 'known_users.txt' list of usernames to search for...
14 usernames loaded.
Extracting 'gather-diagnostics_14d_solace1025_2026-02-22T23.21.18.tgz'...
Unzipping any compressed files inside...
79 files found... stand by.
 ├─ var/log/messages
 ├─ var/log/secure
 ├─ cli-diagnostics.txt
 ├─ log.txt
 ├─ manifest.txt
 ├─ proc/mdstat
 ├─ proc/Octeon0/stats
 ├─ proc/stat
<SNIP>
 ├─ etc/udev/rules.d/10-internal_disks.rules
 ├─ etc/multipath.conf
 ├─ etc/hostname
Scrubbing complete!
Re-tarring diagnostics...
Would you like to encrypt the output file with GPG? (y/n): y
Saved encrypted file. *REMEMBER YOUR PASSWORD* and pass to Solace Support for extract.
Cleaning up...
Use: "gpg -o scrubbed-gather-diagnostics_14d_solace1025_2026-02-22T23.21.18.tgz -d scrubbed-gather-diagnostics_14d_solace1025_2026-02-22T23.21.18.tgz.gpg" to extract.
Done!
```




