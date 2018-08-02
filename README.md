# DESCRIPTION

mimic is a dumbed-down script that can:

 - backup of a list of programs to a private folder;
 - substitute the programs of this list with another;
 - restore the backed-up programs to their original locations.

What this can be useful for is left to your imagination...


# PREREQUISITES

mimic will need you to place the substitution file at: ~/.mimic/noop

A suggestion for the substitution file (actually already hinted at by the
name...) is to use a noop program. This one works fine:

https://github.com/steveschnepp/noop


# USAGE

## Installation (sort of)

Either:

 - copy _mimic.sh_ alone to a place of your choice and run it (it
   will create its folder structure where applicable.)

 - or clone the repo directly under a _${HOME}/.mimic_ folder
   if you want the whole thing.

## Setup

 1. Place the noop file of your choice at: _${HOME}/.mimic/noop_.
 2. Edit the tracker file _${HOME}/.mimic/tracker_ with a list of programs
    to substitute.

## Execution

### Substitute

        ./mimic.sh substitute

### Restore

        ./mimic.sh restore


# FOLDER STRUCTURE

mimic uses the following folder structure under the HOME of the
user running it:

```
${HOME}/
  `-- .mimic/
      |-- backups/   # contains backups of substitute folders
      |-- noop       # the substitute program of your choice
      `-- tracker    # a list of files to replace
```

# LIMITATIONS

Poor mimic isn't very clever:

 - Its backup/restore process only hashes the path in the tracker file to
   recognize them. It won't be able to restore a file if you've removed its
   path from the tracker file.

 - It only allows to substitute a single file for all targets. Could have
   done a lookup system for multiple entries, but couldn't be bothered as
   it was created for a very specific use case.

 - It is subject to the permission level and access restrictions applied to
   the user who runs it.

All in all, this is not so great. It could be MUCH better by:

  - running as daemon monitoring paths to substitute,
  - allowing for multiple substitution files,
  - performing more resilient backups,
  - being more interactive by asking for substitution files and with which
  - user to run depending on the target program,
  - monitoring running processes instead of paths,
  - offering to kill running processes if they block substitution...

At least it tries to not be too destructive.

Meh. Good enough for now. And for me.
