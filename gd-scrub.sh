#!/bin/bash
set -e

CLEANUP_ENABLED=true
USERS_FILE=known_users.txt
#USERS_FILE=emea8-users.txt

# Copyright (c) 2026 Aaron Lee, Solace
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.


if [[ $# -ne 1 ]]; then
  echo
  echo "Error: Invalid number of arguments." >&2
  echo "Usage: $0 gather-diagnostics-blah-blah.tgz" >&2
  echo
  exit 1
fi

if [[ "$1" != *".tgz" ]]; then
  echo
  echo "Error:  Gather Diagnostics filename must end in .tgz, and it can't be encrypted." >&2
  echo "In CLI: enable -> admin -> gather-diagnostics days-of-history n no-encrypt"
  #echo "Usage: $0 gather-diagnostics-blah-blah.tgz" >&2
  echo
  exit 1
fi

echo
echo " ┌──────────────────────────────────────────────────╖"
echo " │ Solace gather-diagnostics username scrubber v1.0 ║"
echo " │       - Aaron Lee | ©2026 | aaron.lee@solace.com ║"
echo " ╘══════════════════════════════════════════════════╝"
echo

echo "Loading '$USERS_FILE' list of usernames to search for..."
# filter out empty/whitespace lines, truncate to 7 chars, and deduplicate
#mapfile -t USERS < <(grep -v '^[[:space:]]*$' "$USERS_FILE" | cut -c1-7 | sort -u)
# for windows line endings
mapfile -t USERS < <(grep -v '^[[:space:]]*$' "$USERS_FILE" | tr -d '\r' | cut -c1-7 | sort -u)
echo "${#USERS[@]} usernames loaded."
# join the array with pipes, very basic borin regex; future: compile into trie, or use hash for faster verification
USERS_REGEX="\b(?:$(IFS='|'; echo "${USERS[*]}"))[0-9a-zA-Z\-_\.\+]*"
export USERS_REGEX
#echo "$USERS_REGEX"

# strip the .tgz off my filename for the 
DIR="${1/.tgz/}"

echo "Extracting '$1'..."
TMP_FOLDER=$(mktemp -d ./tmp-extract-XXXX)
tar xzf $1 -C $TMP_FOLDER
cd "$TMP_FOLDER/$DIR" || exit 1
echo "Unzipping any compressed files inside..."
#find . -name "*.gz" | xargs gunzip
find . -name "*.gz" -exec gunzip {} + || true

# find all "regular" files, count them, shouldn't be more than 250 or so
FILE_COUNT=$(find . -type f -exec grep -I -q . {} \; -print | wc -l)
echo "$FILE_COUNT files found... stand by."
# for each of those regular files, run my Perl script looking for any of those (truncated) usernames, and replace the whole username with the same number of x's
## aaron -> xxxxx
#find . -type f -exec grep -I -q . {} \; -printf '%P\0' | xargs -0 -I {} bash -c 'perl -pi -e "s/(\$ENV{USERS_REGEX})/ \"x\" x length(\$1) /ge; " {}; echo " ├─ {}"'
# aaron -> axxxn   works: perl -e ' my $N="aaron"; my $O=substr($N,0,1) . ("*" x (length($N)-2)) . substr($N,-1,1); print "$O\n"; '
find . -type f -exec grep -I -q . {} \; -printf '%P\0' | xargs -0 -I {} bash -c 'perl -pi -e "s/(\$ENV{USERS_REGEX})/ substr(\$1,0,1).(\"x\" x (length(\$1)-2)).substr(\$1,-1,1) /ge; " {}; echo " ├─ {}"'
echo "Scrubbing complete!"

echo "Re-tarring diagnostics..."
NEW_TAR="scrubbed-$1"
cd ..
tar czf ../$NEW_TAR $DIR
cd ..

read -p "Would you like to encrypt the output file with GPG? (y/n): " DO_ENCRYPT
if [[ "$DO_ENCRYPT" =~ ^[Yy]$ ]]; then
  if gpg -c "$NEW_TAR" 2>/dev/null; then
    echo "Saved encrypted file. *REMEMBER YOUR PASSWORD* and pass to Solace Support for extract."
  else
    echo "Encryption cancelled or failed. Final file: '$NEW_TAR'"
    DO_ENCRYPT="n"
  fi
else
  echo "Encryption skipped. Final file: '$NEW_TAR'"
fi

if [[ "$CLEANUP_ENABLED" == "true" ]]; then
  echo "Cleaning up..."
  rm -rf $TMP_FOLDER
  if [[ "$DO_ENCRYPT" =~ ^[Yy]$ ]]; then
    rm $NEW_TAR
  fi
else
  echo "Skipping cleaning up..."
fi

if [[ "$DO_ENCRYPT" =~ ^[Yy]$ ]]; then
  echo "Use: \"gpg -o $NEW_TAR -d $NEW_TAR.gpg\" to extract."
fi
echo "Done!"
echo

