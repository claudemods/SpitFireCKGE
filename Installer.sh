#!/bin/bash

# Color definition
CYAN='\033[38;2;0;255;255m'
NC='\033[0m' # No Color

# Display ASCII art
echo -e "${CYAN}
░█████╗░██╗░░░░░░█████╗░██╗░░░██╗██████╗░███████╗███╗░░░███╗░█████╗░██████╗░░██████╗
██╔══██╗██║░░░░░██╔══██╗██║░░░██║██╔══██╗██╔════╝████╗░████║██╔══██╗██╔══██╗██╔════╝
██║░░╚═╝██║░░░░░███████║██║░░░██║██║░░██║█████╗░░██╔████╔██║██║░░██║██║░░██║╚█████╗░
██║░░██╗██║░░░░░██╔══██║██║░░░██║██║░░██║██╔══╝░░██║╚██╔╝██║██║░░██║██║░░██║░╚═══██╗
╚█████╔╝███████╗██║░░██║╚██████╔╝██████╔╝███████╗██║░╚═╝░██║╚█████╔╝██████╔╝██████╔╝
░╚════╝░╚══════╝╚═╝░░░░░░╚═════╝░╚═════╝░╚══════╝╚═╝░░░░░╚═╝░╚════╝░╚═════╝░╚═════╝░
${NC}"
echo -e "${CYAN}claudemods Dual Independent System Installer${NC}"
echo

# Function to validate image file
validate_image() {
    if [ ! -f "$1" ]; then
        echo -e "${CYAN}Error: Image file not found!${NC}" >&2
        return 1
    fi
    if [[ "$1" != *.img ]]; then
        echo -e "${CYAN}Error: File must have .img extension${NC}" >&2
        return 1
    fi
    return 0
}

# Function to validate drive
validate_drive() {
    if [ ! -b "$1" ]; then
        echo -e "${CYAN}Error: Drive not found!${NC}" >&2
        return 1
    fi
    return 0
}

# Ask for image file
while true; do
    read -e -p "$(echo -e "${CYAN}Enter path to .img file: ${NC}")" IMG_PATH
    validate_image "$IMG_PATH" && break
done

# Ask for drive
while true; do
    read -e -p "$(echo -e "${CYAN}Enter drive path (e.g., /dev/sda): ${NC}")" DRIVE_PATH
    validate_drive "$DRIVE_PATH" && break
done

# Confirm before proceeding
echo -e "${CYAN}
About to write $IMG_PATH to ${DRIVE_PATH}1 and ${DRIVE_PATH}2${NC}"
read -p "$(echo -e "${CYAN}This will DESTROY ALL DATA on these partitions. Continue? (y/N): ${NC}")" confirm
if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    echo -e "${CYAN}Operation cancelled.${NC}"
    exit 1
fi

# DD the image to first partition
echo -e "${CYAN}Writing image to ${DRIVE_PATH}1...${NC}"
sudo dd if="$IMG_PATH" of="${DRIVE_PATH}1" bs=4M conv=sync,noerror status=progress
echo -e "${CYAN}First system write complete.${NC}"

# DD the image to second partition
echo -e "${CYAN}Writing image to ${DRIVE_PATH}2...${NC}"
sudo dd if="$IMG_PATH" of="${DRIVE_PATH}2" bs=4M conv=sync,noerror status=progress
echo -e "${CYAN}Second system write complete.${NC}"

# First system setup
echo -e "${CYAN}Setting up first system (${DRIVE_PATH}1)...${NC}"
sudo mount "${DRIVE_PATH}1" /mnt
sudo mount --bind /dev /mnt/dev
sudo mount --bind /proc /mnt/proc
sudo mount --bind /sys /mnt/sys
sudo mount --bind /run /mnt/run
sudo mount --bind /dev/pts /mnt/dev/pts

if [ -f "btrfsgenfstabcompressed.sh" ]; then
    sudo cp btrfsgenfstabcompressed.sh /mnt/
    sudo chroot /mnt /btrfsgenfstabcompressed.sh
else
    echo -e "${CYAN}Warning: btrfsgenfstabcompressed.sh not found in current directory${NC}"
fi

# Cleanup after first system
sudo umount /mnt/run
sudo umount /mnt/sys
sudo umount /mnt/proc
sudo umount /mnt/dev/pts
sudo umount /mnt/dev
sudo umount /mnt

# Second system setup
echo -e "${CYAN}Setting up second system (${DRIVE_PATH}2)...${NC}"
sudo mount "${DRIVE_PATH}2" /mnt
sudo mount --bind /dev /mnt/dev
sudo mount --bind /proc /mnt/proc
sudo mount --bind /sys /mnt/sys
sudo mount --bind /run /mnt/run
sudo mount --bind /dev/pts /mnt/dev/pts

if [ -f "btrfsgenfstabcompressed.sh" ]; then
    sudo cp btrfsgenfstabcompressed.sh /mnt/
    sudo chroot /mnt /btrfsgenfstabcompressed.sh
else
    echo -e "${CYAN}Warning: btrfsgenfstabcompressed.sh not found in current directory${NC}"
fi

# Cleanup after second system
sudo umount /mnt/run
sudo umount /mnt/sys
sudo umount /mnt/proc
sudo umount /mnt/dev/pts
sudo umount /mnt/dev
sudo umount /mnt

echo -e "${CYAN}Operation completed successfully! Both systems are now set up independently.${NC}"
