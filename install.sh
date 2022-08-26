#!/bin/bash

source .env

BRIDGE="$2"

NAME="$3"

MAC=$4

K8S_IPADDR="$5"

NETWORK="$NETWORK_KVM"

PATH_DISK="$DISK_KVM"

PATH_ISO="$ISO_KVM"

case $1 in

	"check")

		virt-install --name $NAME\
	--ram 3500 --vcpus 2 --os-type linux\
       	--os-variant=ubuntu18.04 --network bridge=$BRIDGE,model=virtio,mac=${MAC}\
       	--disk path=${PATH_DISK}/${NAME}.qcow2,size=20,device=disk,bus=virtio,cache=none\
       	--cdrom ${PATH_ISO}/talos-amd64-v106.iso\
       	--console pty,target_type=serial --graphics none --virt-type kvm\
       	--noautoconsole --dry-run
		
	;;

	"dhcp-apply")

		virsh net-update --network $NETWORK --command add-last --section ip-dhcp-host --xml "<host mac='${MAC}' name='${NAME}' ip='${K8S_IPADDR}'/>" --live --config

	;;

	"dhcp-delete")

		virsh net-update --network $NETWORK --command delete --section ip-dhcp-host  --xml "<host mac='${MAC}' name='${NAME}' ip='${K8S_IPADDR}'/>" --live --config

	;;

	"install")

			virt-install --name $NAME\
        		--ram 3500 --vcpus 2 --os-type linux\
		        --os-variant=ubuntu18.04 --network bridge=$BRIDGE,model=virtio,mac=${MAC}\
		        --disk path=${PATH_DISK}/${NAME}.qcow2,size=20,device=disk,bus=virtio,cache=none\
	        	--cdrom ${PATH_ISO}/talos-amd64-v106.iso\
		        --console pty,target_type=serial --graphics none --virt-type kvm\
		        --noautoconsole
	;;

	"delete")
		
		virsh destroy ${NAME}

		virsh undefine ${NAME}

		sudo rm -f ${PATH_DISK}/${NAME}.qcow2
	;;

	"delete-all")

		for vm in k8s1 k8s2 k8s3 k8s-worker1 k8s-worker2;do

			virsh destroy ${vm}
			sleep 2
			virsh undefine ${vm}
			sleep 2
			sudo rm -f ${PATH_DISK}/${vm}.qcow2
		done
	;;

esac
