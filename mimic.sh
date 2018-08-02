#!/bin/sh
#
# Copyright (c) 2018 Laurent Malvert <laurent.malvert@gmail.com>
#
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to permit
# persons to whom the Software is furnished to do so, subject to the
# following conditions:
#
# The above copyright notice and this permission notice shall be included
# in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
# OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN
# NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
# DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
# OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE
# USE OR OTHER DEALINGS IN THE SOFTWARE.
#
# -------------------------------------------------------------------------
#
# DESCRIPTION
#
#  mimic is a dumbed-down script that can:
#   - backup of a list of programs to a private folder;
#   - substitute the programs of this list with another;
#   - restore the backed-up programs to their original locations.
#
#  What this can be useful for is left to your imagination...
#
# PREREQUISITES
#
#  mimic will need you to place the substitution file at: ~/.mimic/noop
#
#  A suggestion for the substitution file (actually already hinted at by the
#  name...) is to use a noop program. This one works fine:
#
#  https://github.com/steveschnepp/noop
#
# FOLDER STRUCTURE
#
#  mimic will create the following folder structure under the HOME of the
#  user running it:
#
#      ${HOME}/
#        `-- .mimic/
#             |-- backups/   # contains backups of substitute folders
#             |-- noop       # the substitute program of your choice
#             `-- tracker    # a list of files to replace
#
# LIMITATIONS
#
#  Poor mimic isn't very clever:
#
#   - Its backup/restore process only hashes the path in the tracker file to
#     recognize them. It won't be able to restore a file if you've removed its
#     path from the tracker file.
#
#   - It only allows to substitute a single file for all targets. Could have
#     done a lookup system for multiple entries, but couldn't be bothered as
#     it was created for a very specific use case.
#
#   - It is subject to the permission level and access restrictions applied to
#     the user who runs it.
#
#  All in all, this is not so great. It could be MUCH better by:
#
#    - running as daemon monitoring paths to substitute,
#    - allowing for multiple substitution files,
#    - performing more resilient backups,
#    - being more interactive by asking for substitution files and with which
#    - user to run depending on the target program,
#    - monitoring running processes instead of paths,
#    - offering to kill running processes if they block substitution...
#
#  At least it tries to not be too destructive.
#
#  Meh. Good enough for now. And for me.
#

MIMIC_BASE_FOLDER="${HOME}/.mimic/"
MIMIC_BACK_FOLDER="${MIMIC_BASE_FOLDER}/backups"
MIMIC_TRACKER_FILE="${MIMIC_BASE_FOLDER}/tracker"
MIMIC_NOOP_FILE="${HOME}/.mimic/noop"

mkdir -p "${MIMIC_BACK_FOLDER}"


restore_file() {
    entry="$1"
    bak="$(echo "${entry}" | cksum | cut -f 1 -d ' ')"
    bak_path="${MIMIC_BACK_FOLDER}/${bak}"

    echo "> Restoring ${entry} from ${back} backup..."
    if [ -f "${bak_path}" ]; then
        cp -f -- "${bak_path}" "${entry}" &&
            echo " [+] Restored ${bak_path} to ${entry}."
    else
        echo " [x] Backup file ${bak_path} not found. Skipped."
    fi
}

substitute_file() {
    entry="$1"
    echo "> substituting ${entry}..."
    bak="$(echo "${entry}" | cksum | cut -f 1 -d ' ')"
    bak_path="${MIMIC_BACK_FOLDER}/${bak}"
    if [ -f "${entry}" ]; then
        DO_BACKUP="false"
        DO_SUBTITUTE="false"
        echo "[1] backing up ${entry}..."

        if cmp --silent "${bak_path}" "${entry}"; then
            echo " [-] Entry is already backed up. Backup skipped (no needed)."
        elif cmp --silent "${entry}" "${MIMIC_NOOP_FILE}"; then
            echo " [-] Entry is already substituted. Backup skipped (impossible)."
        else
            cp -f -- "${entry}" "${bak_path}"
            if [ "$?" -eq 0 ]; then
                echo " [+] Backed up ${entry} to ${bak_path}."
            else
                echo " [x] Back up failed. Substitution skipped."
                return 1;
            fi
        fi
        echo "[2] substituting ${entry}..."
        cmp --silent "${entry}" "${MIMIC_NOOP_FILE}"
        if [ "$?" -eq 0 ]; then
            echo " [-] Entry is already substituted. Skipped."
        else
            cp -f -- "${MIMIC_NOOP_FILE}" "${entry}" && \
                echo " [+] Substituted noop for ${entry}"
        fi
    else
        echo "[-] Source file ${entry} does not exist. Skipped."
    fi
}

usage() {
    echo "usage: $0 <cmd>"
    echo ""
    echo "       $0 substitute"
    echo "       $0 restore"
}

if [ "$1" = "restore" ]; then
    while IFS= read -r entry ; do
        restore_file "${entry}"
    done < "${MIMIC_TRACKER_FILE}"
elif [ "$1" = "substitute" ]; then
    if [ -n "$2" ]; then # read additional substitutions from argument list
        for entry in "$@"; do
            echo "$entry" >> "${MIMIC_TRACKER_FILE}"
        done
    fi
    while IFS= read -r entry ; do
        substitute_file "${entry}"
    done < "${MIMIC_TRACKER_FILE}"
else
    usage
fi
