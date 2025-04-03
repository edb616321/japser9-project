#!/bin/bash

# VMware vSphere VM Power Management Tool
# This script provides easy power management for VMware virtual machines

# Set environment variables
export GOVC_URL="10.0.0.230"
export GOVC_USERNAME="administrator@vsphere.local"
export GOVC_PASSWORD="Odroid701963#"
export GOVC_INSECURE=1

# Directory setup
BASE_DIR="$(dirname "$(readlink -f "$0")")"
LOG_DIR="$BASE_DIR/logs"

# Create necessary directories
mkdir -p "$LOG_DIR"

# Logging function
log() {
    local TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")
    local LOG_FILE="$LOG_DIR/vm_power_manager_$(date "+%Y%m%d").log"
    echo "$TIMESTAMP - $1" >> "$LOG_FILE"
}

# Function to show main menu
show_main_menu() {
    clear
    echo "======================================================="
    echo "           VM POWER OPERATIONS TOOL                   "
    echo "======================================================="
    echo "1. List All VMs"
    echo "2. Power On VM"
    echo "3. Power Off VM"
    echo "4. Exit"
    echo "-------------------------------------------------------"
    echo -n "Select an option [1-4]: "
}

# Function to list all VMs
list_vms() {
    clear
    echo "======================================================="
    echo "                  VM LIST                             "
    echo "======================================================="
    echo "Retrieving VM list..."
    
    # Get all VMs and their power states
    echo "-------------------------------------------------------"
    printf "%-40s %-12s %-15s %-15s\n" "VM NAME" "POWER STATE" "VM TOOLS" "IP ADDRESS"
    echo "-------------------------------------------------------"
    
    govc ls /*/vm | grep -v "/vm/template" | while read VM; do
        VM_NAME=$(basename "$VM")
        
        # Skip templates
        IS_TEMPLATE=$(govc vm.info "$VM_NAME" | grep "Template:" | awk '{print $2}')
        if [ "$IS_TEMPLATE" == "true" ]; then
            continue
        fi
        
        VM_INFO=$(govc vm.info "$VM_NAME")
        POWER_STATE=$(echo "$VM_INFO" | grep "Power state:" | awk '{print $3}')
        IP_ADDRESS=$(echo "$VM_INFO" | grep "IP address:" | awk '{print $3}')
        VM_TOOLS=$(echo "$VM_INFO" | grep "VMware Tools:" | awk '{print $3 " " $4}')
        
        printf "%-40s %-12s %-15s %-15s\n" "$VM_NAME" "$POWER_STATE" "$VM_TOOLS" "$IP_ADDRESS"
    done
    
    echo -e "\nNOTE: Missing IP addresses typically indicate VMware Tools issues."
    echo -e "      Ensure VMware Tools is installed and running properly.\n"
    echo "Press Enter to continue..."
    read
}

# Function to display VM selection menu for power on operation
power_on_vm_menu() {
    clear
    echo "======================================================="
    echo "                   POWER ON VM                         "
    echo "======================================================="
    
    # Get list of powered off VMs
    echo "Powered Off VMs:"
    echo "-------------------------------------------------------"
    printf "%-5s %-40s %-15s\n" "NUM" "VM NAME" "DATASTORE"
    echo "-------------------------------------------------------"
    
    declare -a VM_LIST
    VM_COUNT=0
    
    while read -r VM; do
        VM_NAME=$(basename "$VM")
        
        # Skip templates
        IS_TEMPLATE=$(govc vm.info "$VM_NAME" | grep "Template:" | awk '{print $2}')
        if [ "$IS_TEMPLATE" == "true" ]; then
            continue
        fi
        
        # Check power state
        POWER_STATE=$(govc vm.info "$VM_NAME" | grep "Power state:" | awk '{print $3}')
        if [ "$POWER_STATE" == "poweredOff" ]; then
            VM_COUNT=$((VM_COUNT+1))
            DATASTORE=$(govc vm.info -r "$VM_NAME" | grep "File:" | head -1 | sed 's/.*\[\(.*\)\].*/\1/')
            printf "%-5s %-40s %-15s\n" "[$VM_COUNT]" "$VM_NAME" "$DATASTORE"
            VM_LIST[$VM_COUNT]="$VM_NAME"
        fi
    done < <(govc ls /*/vm | grep -v "/vm/template")
    
    if [ $VM_COUNT -eq 0 ]; then
        echo "No powered off VMs found."
        echo "\nPress Enter to continue..."
        read
        return
    fi
    
    echo "\nEnter VM number to power on (or 0 to cancel): "
    read VM_NUMBER
    
    if [ "$VM_NUMBER" == "0" ] || [ -z "$VM_NUMBER" ]; then
        echo "Operation cancelled."
        echo "\nPress Enter to continue..."
        read
        return
    fi
    
    if [ "$VM_NUMBER" -gt "$VM_COUNT" ] || [ "$VM_NUMBER" -lt 1 ]; then
        echo "Invalid VM number selected."
        echo "\nPress Enter to continue..."
        read
        return
    fi
    
    SELECTED_VM="${VM_LIST[$VM_NUMBER]}"
    
    echo "\nPowering on VM: $SELECTED_VM"
    echo "Proceed? (y/n): "
    read CONFIRM
    
    if [ "$CONFIRM" != "y" ]; then
        echo "Operation cancelled."
        echo "\nPress Enter to continue..."
        read
        return
    fi
    
    log "Powering on VM: $SELECTED_VM"
    govc vm.power -on "$SELECTED_VM"
    
    if [ $? -eq 0 ]; then
        echo "VM powered on successfully!"
        log "Successfully powered on VM: $SELECTED_VM"
    else
        echo "Error powering on VM!"
        log "ERROR: Failed to power on VM: $SELECTED_VM"
    fi
    
    echo "\nPress Enter to continue..."
    read
}

# Function to display VM selection menu for power off operation
power_off_vm_menu() {
    clear
    echo "======================================================="
    echo "                   POWER OFF VM                        "
    echo "======================================================="
    
    # Get list of powered on VMs
    echo "Powered On VMs:"
    echo "-------------------------------------------------------"
    printf "%-5s %-40s %-15s\n" "NUM" "VM NAME" "IP ADDRESS"
    echo "-------------------------------------------------------"
    
    declare -a VM_LIST
    VM_COUNT=0
    
    while read -r VM; do
        VM_NAME=$(basename "$VM")
        
        # Skip templates
        IS_TEMPLATE=$(govc vm.info "$VM_NAME" | grep "Template:" | awk '{print $2}')
        if [ "$IS_TEMPLATE" == "true" ]; then
            continue
        fi
        
        # Check power state
        VM_INFO=$(govc vm.info "$VM_NAME")
        POWER_STATE=$(echo "$VM_INFO" | grep "Power state:" | awk '{print $3}')
        if [ "$POWER_STATE" == "poweredOn" ]; then
            VM_COUNT=$((VM_COUNT+1))
            IP_ADDRESS=$(echo "$VM_INFO" | grep "IP address:" | awk '{print $3}')
            printf "%-5s %-40s %-15s\n" "[$VM_COUNT]" "$VM_NAME" "$IP_ADDRESS"
            VM_LIST[$VM_COUNT]="$VM_NAME"
        fi
    done < <(govc ls /*/vm | grep -v "/vm/template")
    
    if [ $VM_COUNT -eq 0 ]; then
        echo "No powered on VMs found."
        echo "\nPress Enter to continue..."
        read
        return
    fi
    
    echo "\nEnter VM number to power off (or 0 to cancel): "
    read VM_NUMBER
    
    if [ "$VM_NUMBER" == "0" ] || [ -z "$VM_NUMBER" ]; then
        echo "Operation cancelled."
        echo "\nPress Enter to continue..."
        read
        return
    fi
    
    if [ "$VM_NUMBER" -gt "$VM_COUNT" ] || [ "$VM_NUMBER" -lt 1 ]; then
        echo "Invalid VM number selected."
        echo "\nPress Enter to continue..."
        read
        return
    fi
    
    SELECTED_VM="${VM_LIST[$VM_NUMBER]}"
    
    echo "\nPowering off VM: $SELECTED_VM"
    echo "This will initiate a graceful shutdown. For a forced power off, use option 5."
    echo "Proceed? (y/n): "
    read CONFIRM
    
    if [ "$CONFIRM" != "y" ]; then
        echo "Operation cancelled."
        echo "\nPress Enter to continue..."
        read
        return
    fi
    
    log "Powering off VM: $SELECTED_VM"
    govc vm.power -off "$SELECTED_VM"
    
    if [ $? -eq 0 ]; then
        echo "VM powered off successfully!"
        log "Successfully powered off VM: $SELECTED_VM"
    else
        echo "Error powering off VM!"
        log "ERROR: Failed to power off VM: $SELECTED_VM"
    fi
    
    echo "\nPress Enter to continue..."
    read
}

# Main program loop
while true; do
    show_main_menu
    read OPTION
    
    case $OPTION in
        1)
            list_vms
            ;;
        2)
            power_on_vm_menu
            ;;
        3)
            power_off_vm_menu
            ;;
        4)
            echo "\nExiting VM Power Manager. Goodbye!"
            exit 0
            ;;
        *)
            echo "Invalid option."
            echo "\nPress Enter to continue..."
            read
            ;;
    esac
done
