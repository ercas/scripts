#!/usr/bin/python3
# frontend for running rsync remote backup commands

import argparse, os, shlex, subprocess, sys, time

# default variables to be edited before running this script
user_local = os.getlogin()
user_remote = None
targets = {

    "template": { # name of the target
        "source": "/path/to/source/directory", # source directory
        "destination": "/path/to/remote/directory/", # destination directory
        "excludes": [], # directories to exclude
        "extra-args": [] # default: -vaAE --delete --delete-excluded --ignore-errors --progress
    }

}

def main():
    parser = argparse.ArgumentParser(description='Process some integers.')
    parser.add_argument("target", help = "directory to sync")
    parser.add_argument("hostname", help = "hostname of backup server")
    args = parser.parse_args()

    if args.target in targets:
        target = targets[args.target]
        if not os.path.isdir(target["source"]):
            print("ERROR: source directory \"" + target["source"] + "\" does not exist.")
            sys.exit(1)
    else:
        print("ERROR: \"" + args.target + "\" is not a valid target. possible targets:")
        print("    " . join([target for target in targets]))
        sys.exit(1)

    # use torsocks if the backup server is behind a .onion service
    rsync_base_cmd = "rsync -vaAE -e ssh --delete --delete-excluded --ignore-errors --progress"
    mkdir_base_cmd = "ssh " + user_remote + "@" + args.hostname + " mkdir -p " + target["destination"]
    if ".onion" in args.hostname:
        print("NOTICE: onion service detected; using torsocks.")
        rsync_base_cmd = "torsocks " + rsync_base_cmd
        mkdir_base_cmd = "torsocks " + mkdir_base_cmd

    # create the remote directory if it doesn't exist yet and back up to it
    mkdir_cmd = shlex.split(mkdir_base_cmd)
    rsync_cmd = shlex.split(rsync_base_cmd) \
        + [extra_arg for extra_arg in target["extra-args"]] \
        + ["--exclude=" + exclude for exclude in target["excludes"]] \
        + [target["source"], user_remote + "@" + args.hostname + ":" + target["destination"]]
    print(" ".join(mkdir_cmd))
    subprocess.call(mkdir_cmd)
    print("running this command in 5 seconds:\n" + " ".join(rsync_cmd))
    time.sleep(5)
    subprocess.call(rsync_cmd)

if __name__ == "__main__":
    if user_remote is None:
        print("ERROR: this script has not been configured properly.")
        print("please open this script in a text editor and set the variables")
        print("at the beginning of the script.")
        sys.exit(1)
    main()
