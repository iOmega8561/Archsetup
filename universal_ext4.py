#!/usr/bin/python3
from libutils import console, linux
import os

def main():

    with open("/etc/os-release", "r") as release:
        
        if not "Arch Linux" in release.read():

			# Exit if system is not Arch Linux
            console.log("This is not the Arch Linux Installation media.", "err")
            exit(1)

    if not linux.isroot():

        # Exit if not a root user
        console.log("Not a root user. Is this the Arch Installation media?", "err")
        exit(1)
    
    console.log("Root partition must have EXT4 fs and /mnt mountpoint", "wrn")
    console.log("Do you still want to run this Installation Script?")

    answer = input("Answer: ")
    if not any(x in answer for x in ["Yes", "yes", "y", "Y"]):
        return
    
    

    

if __name__ == "__main__":
    main()