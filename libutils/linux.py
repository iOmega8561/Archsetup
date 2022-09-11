import subprocess, json

def __lsblk():
    lsblk = subprocess.run(
        ["lsblk", "-J", "-fs", "--output=NAME,FSTYPE,UUID,MOUNTPOINTS"],
        stdout = subprocess.PIPE,
        stderr = subprocess.STDOUT,
        check  = True,
        text   = True
    )

    blockdevices = json.loads(lsblk.stdout)

    return blockdevices["blockdevices"]

def isroot():
    whoami = subprocess.run(
        ["whoami"],
        stdout = subprocess.PIPE,
        check = True,
        text  = True
    )

    if whoami.stdout.rstrip("\n") == "root":
        return True

def bash(command):

    # Invoke shell subprocess
    shell = subprocess.run(
        [command],
        check = True,
        text  = True,
        shell = True
    )

    return shell

def findmount(mountpoint: str):

    # Get block devices from lsblk
    blockdevices = __lsblk()

    for device in blockdevices:
            
        # Check if mountpoint exists in device mountpoints
        if mountpoint in device["mountpoints"]:

            # If yes, return device
            return device

        # Check every device child if it has any
        for child in device["children"] if "children" in device.keys() else []:

            # Check if mountpoint exists
            if mountpoint in child["mountpoints"]:

                # Return child
                return child