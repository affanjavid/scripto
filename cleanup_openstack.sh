#!/bin/bash
#Affan Javid .
# ========================================================
# WARNING: USE THIS SCRIPT AT YOUR OWN RISK
#
# This script is provided "as is" without any warranty 
# of any kind, either express or implied, including but 
# not limited to the implied warranties of merchantability, 
# fitness for a particular purpose, or non-infringement. 
# In no event shall the author or contributors be liable 
# for any direct, indirect, incidental, special, exemplary, 
# or consequential damages (including, but not limited to, 
# procurement of substitute goods or services; loss of use, 
# data, or profits; or business interruption) however caused 
# and on any theory of liability, whether in contract, strict 
# liability, or tort (including negligence or otherwise) 
# arising in any way out of the use of this script, even if 
# advised of the possibility of such damage.
#
# It is highly recommended that you review and test this 
# script in a controlled environment before using it on any 
# production system. The user assumes full responsibility for 
# any issues that may arise from using this script.
# ========================================================

# based on https://discourse.ubuntu.com/t/scaling-down-the-cluster/38982
# Function to clean up each disk listed by microceph
clean_microceph_disks() {
    echo "Listing microceph disks..."
    disks=$(sudo microceph disk list | grep "/dev/disk/by-id/" | awk '{print $1}')
    
    if [ -z "$disks" ]; then
        echo "No disks found by microceph."
        return
    fi

    echo "Cleaning microceph disks..."
    for disk in $disks; do
        echo "Cleaning disk: $disk"
        sudo dd if=/dev/zero of="$disk" bs=4M count=10 status=progress
    done
    echo "Disk clean-up completed."
}

# Step 1: Destroy the Juju model with storage
echo "Destroying Juju model: openstack"
juju destroy-model --destroy-storage --no-prompt --force --no-wait openstack
wait

# Step 2: Destroy the Juju controller
echo "Destroying Juju controller: sunbeam-controller"
juju destroy-controller --no-prompt --destroy-storage --force --no-wait sunbeam-controller
wait

# Step 3: Remove the Juju agent services
echo "Removing Juju agent services"
sudo /sbin/remove-juju-services
wait

# Step 4: Remove the Juju snap
echo "Removing Juju snap"
sudo snap remove --purge juju
wait

# Step 5: Remove Juju configuration
echo "Removing Juju configuration"
rm -rf ~/.local/share/juju
sudo rm -rf /var/lib/juju/dqlite
sudo rm -rf /var/lib/juju/system-identity
sudo rm -rf /var/lib/juju/bootstrap-params
wait

# Step 6: Remove the OpenStack hypervisor and OpenStack snaps
echo "Removing OpenStack hypervisor and OpenStack snaps"
sudo snap remove --purge openstack-hypervisor
sudo snap remove --purge openstack
wait

# Step 7: Remove OpenStack snap configuration
echo "Removing OpenStack snap configuration"
rm -rf ~/.local/share/openstack
wait

# Step 8: Leave and remove MicroK8s
echo "Leaving and removing MicroK8s snap"
sudo microk8s leave
sudo snap remove --purge microk8s
wait

# Step 9: Clean up MicroCeph disks
clean_microceph_disks
wait

# Step 10: Remove the MicroCeph snap
echo "Removing MicroCeph snap"
sudo snap remove --purge microceph
wait

echo "Cleanup completed!"
