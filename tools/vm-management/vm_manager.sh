#!/bin/bash

# VMware vSphere VM Management Tool
# This script provides an interactive interface for managing VMware virtual machines

# Set environment variables
export GOVC_URL="10.0.0.230"
export GOVC_USERNAME="administrator@vsphere.local"
export GOVC_PASSWORD="Odroid701963#"
export GOVC_INSECURE=1

# Directory setup
BASE_DIR="$(dirname "$(readlink -f "$0")")"
LOG_DIR="$BASE_DIR/logs"
INVENTORY_DIR="$BASE_DIR/reports"

# Create necessary directories
mkdir -p "$LOG_DIR" "$INVENTORY_DIR"

# SSH credentials for VM access
SSH_USER="root"
SSH_PASS="Rathersimple123"

# Logging function
log() {
    local TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")
    local LOG_FILE="$LOG_DIR/vm_manager_$(date "+%Y%m%d").log"
    echo "$TIMESTAMP - $1" >> "$LOG_FILE"
}

# Function to show main menu
show_main_menu() {
    clear
    echo "======================================================="
    echo "           VMWARE VSPHERE MANAGEMENT TOOL             "
    echo "======================================================="
    echo "1. VM Information and Inventory"
    echo "2. VM Creation and Deployment"
    echo "3. VM Network Configuration"
    echo "4. VM Power Operations"
    echo "5. Template Management"
    echo "6. Generate Reports"
    echo "7. Exit"
    echo "-------------------------------------------------------"
    echo -n "Select an option [1-7]: "
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
    printf "%-40s %-12s %-15s\n" "VM NAME" "POWER STATE" "IP ADDRESS"
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
        printf "%-40s %-12s %-15s\n" "$VM_NAME" "$POWER_STATE" "$IP_ADDRESS"
    done
    
    echo "\nPress Enter to continue..."
    read
}

# Function to get detailed VM information
get_vm_details() {
    clear
    echo "======================================================="
    echo "              VM DETAILS                              "
    echo "======================================================="
    
    # List VMs
    echo "Available VMs:"
    echo "-------------------------------------------------------"
    printf "%-40s %-12s\n" "VM NAME" "POWER STATE"
    echo "-------------------------------------------------------"
    
    declare -a VM_NAMES
    
    while read -r VM; do
        VM_NAME=$(basename "$VM")
        
        # Skip templates
        IS_TEMPLATE=$(govc vm.info "$VM_NAME" | grep "Template:" | awk '{print $2}')
        if [ "$IS_TEMPLATE" == "true" ]; then
            continue
        fi
        
        POWER_STATE=$(govc vm.info "$VM_NAME" | grep "Power state:" | awk '{print $3}')
        printf "%-40s %-12s\n" "$VM_NAME" "$POWER_STATE"
        VM_NAMES+=("$VM_NAME")
    done < <(govc ls /*/vm | grep -v "/vm/template")
    
    echo "\nEnter VM name for detailed information: "
    read SELECTED_VM
    
    # Get VM details
    VM_INFO=$(govc vm.info "$SELECTED_VM" 2>/dev/null)
    if [ $? -ne 0 ]; then
        echo "VM not found: $SELECTED_VM"
        echo "\nPress Enter to continue..."
        read
        return
    fi
    
    clear
    echo "======================================================="
    echo "     DETAILED VM INFORMATION: $SELECTED_VM            "
    echo "======================================================="
    echo "$VM_INFO" | grep -E "Name:|Guest name:|CPU:|Memory:|Power state:|Boot time:|IP address:|Storage:|Template:|Path:|UUID:|Guest hostname:"
    
    # Network information
    echo "\n---------- NETWORK INFORMATION ----------"
    govc device.info -vm "$SELECTED_VM" ethernet-0 2>/dev/null
    
    # Additional information if VM is powered on
    POWER_STATE=$(echo "$VM_INFO" | grep "Power state:" | awk '{print $3}')
    IP_ADDRESS=$(echo "$VM_INFO" | grep "IP address:" | awk '{print $3}')
    
    if [ "$POWER_STATE" == "poweredOn" ] && [ ! -z "$IP_ADDRESS" ]; then
        echo "\n---------- LIVE SYSTEM INFORMATION ----------"
        echo "Attempting to connect to VM for additional information..."
        
        # Try to get system information
        HOSTNAME=$(sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=3 "$SSH_USER@$IP_ADDRESS" 'hostname' 2>/dev/null)
        OS_INFO=$(sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=3 "$SSH_USER@$IP_ADDRESS" 'cat /etc/os-release | grep PRETTY_NAME' 2>/dev/null)
        UPTIME=$(sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=3 "$SSH_USER@$IP_ADDRESS" 'uptime' 2>/dev/null)
        DISK_USAGE=$(sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=3 "$SSH_USER@$IP_ADDRESS" 'df -h | grep -v tmp' 2>/dev/null)
        
        if [ ! -z "$HOSTNAME" ]; then
            echo "Hostname: $HOSTNAME"
            echo "OS: $OS_INFO"
            echo "Uptime: $UPTIME"
            echo "\nDisk Usage:"
            echo "$DISK_USAGE"
        else
            echo "Could not connect to VM via SSH. The VM may not have SSH enabled or credentials might be incorrect."
        fi
    fi
    
    echo "\nPress Enter to continue..."
    read
}

# ENHANCED: Function for VM power operations with numbered selection menu
vm_power_operations() {
    clear
    echo "======================================================="
    echo "              VM POWER OPERATIONS                     "
    echo "======================================================="
    echo "1. Power On VM"
    echo "2. Power Off VM"
    echo "3. Restart VM"
    echo "4. Force Power Off VM"
    echo "5. Back to Main Menu"
    echo "-------------------------------------------------------"
    echo -n "Select an option [1-5]: "
    read POWER_OPTION
    
    case $POWER_OPTION in
        1)
            power_on_vm_menu
            ;;
        2)
            power_off_vm_menu
            ;;
        3)
            restart_vm_menu
            ;;
        4)
            force_off_vm_menu
            ;;
        5)
            return
            ;;
        *)
            echo "Invalid option."
            echo "\nPress Enter to continue..."
            read
            ;;
    esac
}

# ENHANCED: Function to display VM selection menu for power on operation
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

# ENHANCED: Function to display VM selection menu for power off operation
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
    echo "This will initiate a graceful shutdown. For a forced power off, use option 4."
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

# ENHANCED: Function to display VM selection menu for restart operation
restart_vm_menu() {
    clear
    echo "======================================================="
    echo "                   RESTART VM                          "
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
    
    echo "\nEnter VM number to restart (or 0 to cancel): "
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
    
    echo "\nRestarting VM: $SELECTED_VM"
    echo "This will initiate a graceful restart."
    echo "Proceed? (y/n): "
    read CONFIRM
    
    if [ "$CONFIRM" != "y" ]; then
        echo "Operation cancelled."
        echo "\nPress Enter to continue..."
        read
        return
    fi
    
    log "Restarting VM: $SELECTED_VM"
    govc vm.power -reset "$SELECTED_VM"
    
    if [ $? -eq 0 ]; then
        echo "VM restart initiated successfully!"
        log "Successfully initiated restart for VM: $SELECTED_VM"
    else
        echo "Error restarting VM!"
        log "ERROR: Failed to restart VM: $SELECTED_VM"
    fi
    
    echo "\nPress Enter to continue..."
    read
}

# ENHANCED: Function to display VM selection menu for force power off operation
force_off_vm_menu() {
    clear
    echo "======================================================="
    echo "                 FORCE POWER OFF VM                    "
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
    
    echo "\nEnter VM number to force power off (or 0 to cancel): "
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
    
    echo "\nWARNING: Force powering off VM: $SELECTED_VM"
    echo "This is equivalent to pulling the power plug and may cause data corruption."
    echo "Are you absolutely sure? (yes/no): "
    read CONFIRM
    
    if [ "$CONFIRM" != "yes" ]; then
        echo "Operation cancelled."
        echo "\nPress Enter to continue..."
        read
        return
    fi
    
    log "Force powering off VM: $SELECTED_VM"
    # Note: govc vm.power -s=true -force used for hard power off
    govc vm.power -off -force "$SELECTED_VM"
    
    if [ $? -eq 0 ]; then
        echo "VM force powered off successfully!"
        log "Successfully force powered off VM: $SELECTED_VM"
    else
        echo "Error force powering off VM!"
        log "ERROR: Failed to force power off VM: $SELECTED_VM"
    fi
    
    echo "\nPress Enter to continue..."
    read
}

# ENHANCED: Function to create VM from template with numbered menu selection
create_vm_from_template() {
    clear
    echo "======================================================="
    echo "             CREATE VM FROM TEMPLATE                  "
    echo "======================================================="
    
    # Get list of templates
    echo "Available Templates:"
    echo "-------------------------------------------------------"
    printf "%-5s %-40s %-15s\n" "NUM" "TEMPLATE NAME" "DATASTORE"
    echo "-------------------------------------------------------"
    
    declare -a TEMPLATE_LIST
    TEMPLATE_COUNT=0
    
    while read -r VM; do
        if [ -z "$VM" ]; then
            continue
        fi
        
        VM_NAME=$(basename "$VM")
        
        # Check if it's a template
        IS_TEMPLATE=$(govc vm.info "$VM_NAME" | grep "Template:" | awk '{print $2}')
        if [ "$IS_TEMPLATE" == "true" ]; then
            TEMPLATE_COUNT=$((TEMPLATE_COUNT+1))
            DATASTORE=$(govc vm.info -r "$VM_NAME" | grep "File:" | head -1 | sed 's/.*\[\(.*\)\].*/\1/')
            printf "%-5s %-40s %-15s\n" "[$TEMPLATE_COUNT]" "$VM_NAME" "$DATASTORE"
            TEMPLATE_LIST[$TEMPLATE_COUNT]="$VM_NAME"
        fi
    done < <(govc ls /*/vm)
    
    if [ $TEMPLATE_COUNT -eq 0 ]; then
        echo "No templates found."
        echo "\nPress Enter to continue..."
        read
        return
    fi
    
    echo "\nEnter template number to use (or 0 to cancel): "
    read TEMPLATE_NUMBER
    
    if [ "$TEMPLATE_NUMBER" == "0" ] || [ -z "$TEMPLATE_NUMBER" ]; then
        echo "Operation cancelled."
        echo "\nPress Enter to continue..."
        read
        return
    fi
    
    if [ "$TEMPLATE_NUMBER" -gt "$TEMPLATE_COUNT" ] || [ "$TEMPLATE_NUMBER" -lt 1 ]; then
        echo "Invalid template number selected."
        echo "\nPress Enter to continue..."
        read
        return
    fi
    
    SELECTED_TEMPLATE="${TEMPLATE_LIST[$TEMPLATE_NUMBER]}"
    
    echo "\nSelected template: $SELECTED_TEMPLATE"
    
    # Get VM name
    echo "\nEnter name for the new VM (must follow naming convention with IP at the end, e.g., SUPABASE-170): "
    read NEW_VM_NAME
    
    if [ -z "$NEW_VM_NAME" ]; then
        echo "VM name cannot be empty. Operation cancelled."
        echo "\nPress Enter to continue..."
        read
        return
    fi
    
    # Extract IP from VM name (assuming format NAME-XXX where XXX is the last octet)
    IP_LAST_OCTET=$(echo "$NEW_VM_NAME" | grep -oE '[0-9]+$')
    if [ -z "$IP_LAST_OCTET" ]; then
        echo "VM name must include the IP number at the end (e.g., SUPABASE-170)."
        echo "\nPress Enter to continue..."
        read
        return
    fi
    
    NEW_IP="10.0.0.$IP_LAST_OCTET"
    
    # Check if the IP is already in use
    echo "Checking if IP $NEW_IP is already in use..."
    IP_CHECK=$(govc find / -type m -summary.guest.ipAddress $NEW_IP)
    
    if [ ! -z "$IP_CHECK" ]; then
        echo "WARNING: IP address $NEW_IP appears to be already in use by $(basename "$IP_CHECK")"
        echo "Would you like to continue anyway? (y/n): "
        read CONTINUE_ANYWAY
        
        if [ "$CONTINUE_ANYWAY" != "y" ]; then
            echo "Operation cancelled."
            echo "\nPress Enter to continue..."
            read
            return
        fi
    fi
    
    # Choose datastore
    clear
    echo "======================================================="
    echo "             SELECT DATASTORE                         "
    echo "======================================================="
    
    echo "Available Datastores:"
    echo "-------------------------------------------------------"
    printf "%-5s %-30s %-15s %-15s\n" "NUM" "DATASTORE" "CAPACITY" "FREE SPACE"
    echo "-------------------------------------------------------"
    
    declare -a DATASTORE_LIST
    DATASTORE_COUNT=0
    
    govc datastore.info -json | jq -r '.Datastores[] | [.Name, .Summary.Capacity, .Summary.FreeSpace] | @tsv' | while IFS=$'\t' read -r NAME CAPACITY FREE; do
        DATASTORE_COUNT=$((DATASTORE_COUNT+1))
        CAPACITY_GB=$(echo "scale=1; $CAPACITY/1073741824" | bc)
        FREE_GB=$(echo "scale=1; $FREE/1073741824" | bc)
        printf "%-5s %-30s %-15s %-15s\n" "[$DATASTORE_COUNT]" "$NAME" "${CAPACITY_GB}GB" "${FREE_GB}GB"
        DATASTORE_LIST[$DATASTORE_COUNT]="$NAME"
    done
    
    echo "\nEnter datastore number (or press Enter for default): "
    read DATASTORE_NUMBER
    
    if [ -z "$DATASTORE_NUMBER" ]; then
        # Use the same datastore as the template
        DATASTORE=$(govc vm.info -r "$SELECTED_TEMPLATE" | grep "File:" | head -1 | sed 's/.*\[\(.*\)\].*/\1/')
    elif [ "$DATASTORE_NUMBER" -gt "$DATASTORE_COUNT" ] || [ "$DATASTORE_NUMBER" -lt 1 ]; then
        echo "Invalid datastore number. Using template's datastore."
        DATASTORE=$(govc vm.info -r "$SELECTED_TEMPLATE" | grep "File:" | head -1 | sed 's/.*\[\(.*\)\].*/\1/')
    else
        DATASTORE="${DATASTORE_LIST[$DATASTORE_NUMBER]}"
    fi
    
    echo "\nUsing datastore: $DATASTORE"
    
    # Confirm creation
    echo "\nReady to create VM '$NEW_VM_NAME' from template '$SELECTED_TEMPLATE'."
    echo "IP Address will be configured as: $NEW_IP"
    echo "Datastore: $DATASTORE"
    echo "\nProceed? (y/n): "
    read CONFIRM
    
    if [ "$CONFIRM" != "y" ]; then
        echo "VM creation cancelled."
        echo "\nPress Enter to continue..."
        read
        return
    fi
    
    # Create the VM
    echo "\nCreating new VM from template..."
    log "Creating VM $NEW_VM_NAME from template $SELECTED_TEMPLATE"
    
    govc vm.clone -vm "$SELECTED_TEMPLATE" -on=false -ds="$DATASTORE" "$NEW_VM_NAME"
    
    if [ $? -ne 0 ]; then
        echo "Error creating VM!"
        log "ERROR: Failed to create VM $NEW_VM_NAME from template $SELECTED_TEMPLATE"
        echo "\nPress Enter to continue..."
        read
        return
    fi
    
    echo "VM created successfully!"
    log "Successfully created VM $NEW_VM_NAME from template $SELECTED_TEMPLATE"
    
    # Configure network settings
    echo "\nConfiguring network settings..."
    
    # Power on the VM first
    echo "Powering on VM to configure network..."
    govc vm.power -on "$NEW_VM_NAME"
    
    # Wait for VM to boot
    echo "Waiting for VM to boot..."
    sleep 30
    
    # Get current IP
    CURRENT_IP=$(govc vm.info "$NEW_VM_NAME" | grep "IP address:" | awk '{print $3}')
    
    if [ -z "$CURRENT_IP" ]; then
        echo "Could not detect VM's current IP address. You may need to configure the network manually."
    else
        echo "Current IP address: $CURRENT_IP"
        echo "Attempting to update to requested IP: $NEW_IP"
        
        # Configure network settings
        configure_vm_network "$NEW_VM_NAME" "$CURRENT_IP" "$NEW_IP"
    fi
    
    echo "\nVM creation and configuration completed."
    echo "\nPress Enter to continue..."
    read
}

# Function to configure VM network settings
configure_vm_network() {
    local VM_NAME=$1
    local CURRENT_IP=$2
    local NEW_IP=$3
    
    echo "\nConfiguring network for VM: $VM_NAME"
    echo "  Current IP: $CURRENT_IP"
    echo "  Target IP:  $NEW_IP"
    
    # Capture octets for easier reference
    IFS='.' read -r -a CURRENT_OCTETS <<< "$CURRENT_IP"
    IFS='.' read -r -a NEW_OCTETS <<< "$NEW_IP"
    
    # Connect to VM via SSH and update network configuration
    echo "\nConnecting to VM to update network configuration..."
    
    # First check SSH connectivity
    sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 "$SSH_USER@$CURRENT_IP" 'echo "SSH connection successful"' > /dev/null 2>&1
    
    if [ $? -ne 0 ]; then
        echo "ERROR: Could not connect to VM via SSH. Network configuration must be done manually."
        log "ERROR: SSH connection failed for VM $VM_NAME ($CURRENT_IP)"
        return 1
    fi
    
    # Update network configuration based on OS detection
    OS_TYPE=$(sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no "$SSH_USER@$CURRENT_IP" 'if [ -f /etc/os-release ]; then grep -oP "(?<=^ID=).*" /etc/os-release | tr -d "\"\'"; fi')
    
    case "$OS_TYPE" in
        ubuntu|debian)
            # Ubuntu/Debian style
            echo "Detected Ubuntu/Debian system"
            INTERFACES_FILE="/etc/network/interfaces"
            
            # Create new config
            sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no "$SSH_USER@$CURRENT_IP" "cat > /tmp/interfaces << 'EOF'
# Network configuration written by vm-manager
auto lo
iface lo inet loopback

auto ens192
iface ens192 inet static
    address $NEW_IP
    netmask 255.255.255.0
    gateway 10.0.0.1
    dns-nameservers 10.0.0.1 1.1.1.1
EOF"
            
            # Apply new config
            sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no "$SSH_USER@$CURRENT_IP" \
                "sudo cp /tmp/interfaces $INTERFACES_FILE && \
                 echo 'Network configuration updated. Restarting networking service...' && \
                 sudo systemctl restart networking"
            ;;
        
        centos|rhel|fedora)
            # CentOS/RHEL style
            echo "Detected CentOS/RHEL system"
            
            # Find the network interface name
            IFACE=$(sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no "$SSH_USER@$CURRENT_IP" "ip route | grep default | awk '{print \$5}'")
            
            # Create new config
            sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no "$SSH_USER@$CURRENT_IP" "cat > /tmp/ifcfg-$IFACE << 'EOF'
TYPE=Ethernet
PROXY_METHOD=none
BROWSER_ONLY=no
BOOTPROTO=static
DEFROUTE=yes
IPV4_FAILURE_FATAL=no
IPV6INIT=no
NAME=$IFACE
DEVICE=$IFACE
ONBOOT=yes
IPADDR=$NEW_IP
PREFIX=24
GATEWAY=10.0.0.1
DNS1=10.0.0.1
DNS2=1.1.1.1
EOF"
            
            # Apply new config
            sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no "$SSH_USER@$CURRENT_IP" \
                "sudo cp /tmp/ifcfg-$IFACE /etc/sysconfig/network-scripts/ && \
                 echo 'Network configuration updated. Restarting networking service...' && \
                 sudo systemctl restart network"
            ;;
        
        *)
            # Generic approach - Try using netplan for modern systems
            echo "Could not detect specific OS type, trying generic approach"
            
            # Check if netplan is available
            HAS_NETPLAN=$(sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no "$SSH_USER@$CURRENT_IP" "command -v netplan > /dev/null && echo yes || echo no")
            
            if [ "$HAS_NETPLAN" == "yes" ]; then
                echo "Using netplan for network configuration"
                
                # Find network interface name
                IFACE=$(sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no "$SSH_USER@$CURRENT_IP" "ip route | grep default | awk '{print \$5}'")
                
                # Create netplan config
                sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no "$SSH_USER@$CURRENT_IP" "cat > /tmp/01-netcfg.yaml << 'EOF'
network:
  version: 2
  renderer: networkd
  ethernets:
    $IFACE:
      dhcp4: no
      addresses:
        - $NEW_IP/24
      gateway4: 10.0.0.1
      nameservers:
        addresses: [10.0.0.1, 1.1.1.1]
EOF"
                
                # Apply netplan config
                sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no "$SSH_USER@$CURRENT_IP" \
                    "sudo cp /tmp/01-netcfg.yaml /etc/netplan/ && \
                     echo 'Network configuration updated. Applying netplan...' && \
                     sudo netplan apply"
            else
                echo "WARNING: Could not determine the network configuration method."
                echo "Please update the network configuration manually to $NEW_IP"
                return 1
            fi
            ;;
    esac
    
    # Update hostname to match VM name
    NEW_HOSTNAME=$(echo "$VM_NAME" | tr '[:upper:]' '[:lower:]')
    echo "Updating hostname to: $NEW_HOSTNAME"
    
    sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no "$SSH_USER@$CURRENT_IP" \
        "sudo hostnamectl set-hostname $NEW_HOSTNAME && \
         echo 'Hostname updated to $NEW_HOSTNAME'"
    
    # Remind the user about the IP change
    echo "\nNetwork configuration updated. VM will now use IP: $NEW_IP"
    echo "IMPORTANT: You must reconnect to the VM using the new IP address."
    
    log "Updated network configuration for VM $VM_NAME from $CURRENT_IP to $NEW_IP"
    
    return 0
}

# Function to show VM creation submenu
vm_creation_submenu() {
    while true; do
        clear
        echo "======================================================="
        echo "         VM CREATION AND DEPLOYMENT                   "
        echo "======================================================="
        echo "1. Create VM from Template"
        echo "2. Back to Main Menu"
        echo "-------------------------------------------------------"
        echo -n "Select an option [1-2]: "
        read CREATE_OPTION
        
        case $CREATE_OPTION in
            1)
                create_vm_from_template
                ;;
            2)
                return
                ;;
            *)
                echo "Invalid option."
                echo "\nPress Enter to continue..."
                read
                ;;
        esac
    done
}

while true; do
    show_main_menu
    read OPTION
    
    case $OPTION in
        1)
            list_vms
            ;;
        2)
            vm_creation_submenu
            ;;
        3)
            # VM network configuration
            ;;
        4)
            vm_power_operations
            ;;
        5)
            # Template management
            ;;
        6)
            # Generate reports
            ;;
        7)
            echo "\nExiting VM Manager. Goodbye!"
            exit 0
            ;;
        *)
            echo "Invalid option."
            echo "\nPress Enter to continue..."
            read
            ;;
    esac
done
