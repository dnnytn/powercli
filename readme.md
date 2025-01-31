# vCenter Automation Script for Running Scripts on ESXi Hosts

## Background

This script is designed to automate tasks on **VMware vCenter** environments using **PowerCLI**. Specifically, it manages two types of scripts located within a folder called **`run-scripts`**:

- **runonce**: Scripts that should only be run once. Once executed, they are moved to an archive folder so they don't run again.
- **cron**: Scripts that should run continuously or on demand.

The script connects to vCenter, enables SSH on all ESXi hosts, runs the scripts located in the `run-scripts` folder based on their naming convention (`runonce-` for one-time scripts and others for continuous scripts), logs activities, and cleans up afterward by disabling SSH on the hosts.

Additionally, the script ensures logs older than one year are purged for housekeeping and makes the process automated and unattended.

---

## Prerequisites

- **PowerCLI**: VMware PowerCLI must be installed on the system running this script. [Installation guide for PowerCLI](https://developer.vmware.com/powercli).
- **Access to vCenter**: The script requires access to a **vCenter Server** and sufficient privileges to execute scripts on the ESXi hosts.
- **SSH Access to ESXi Hosts**: SSH must be enabled on ESXi hosts for script execution.
- **Run-Scripts Folder**: The folder containing the scripts to be run. The scripts must follow the naming convention (`runonce-<name>.sh` for one-time scripts and others for continuous execution).

---

## How the Script Works

1. **Connects to vCenter**: The script connects to the specified vCenter server using provided credentials.
2. **Enables SSH**: It enables SSH on each ESXi host for script execution.
3. **Identifies Script Types**: It checks the **`run-scripts`** folder for scripts:
   - **`runonce-<name>.sh`**: These scripts are only executed once. After running, they are moved to an **`archive`** folder.
   - Other scripts are executed continuously based on their filename pattern.
4. **Execution**: The script is executed on each ESXi host.
5. **Logging**: Execution details are logged to a file for tracking and troubleshooting.
6. **SSH Cleanup**: After script execution, SSH access is disabled on the ESXi hosts.
7. **Log Housekeeping**: Logs older than 1 year are purged.

---

## Usage Instructions

### 1. **Prepare the Environment**

- Ensure that **PowerCLI** is installed on the machine where you will be running this script.
- Ensure that you have access to the **vCenter** server with appropriate credentials.
- Set up the **run-scripts** folder and place your shell scripts (`*.sh`) there.
  - Scripts prefixed with **`runonce-`** will be executed once and archived.
  - Other scripts will be executed continuously.

### 2. **Configure the Script**

Modify the script as needed:

- Update the **vCenter Server** address, username, and password in the script.
- Set the correct paths for the **run-scripts** folder, **archive folder**, and **log file**.

Example:

```powershell
# Set vCenter server details
$vCenterServer = "<vCenter_Server>"
$vCenterUser = "<Username>"
$vCenterPassword = "<Password>"

# Set the paths for scripts, logs, and archives
$scriptFolder = "/path/to/run-scripts"
$archiveFolder = "/path/to/archive"
$logFile = "/path/to/logfile.log"
```
