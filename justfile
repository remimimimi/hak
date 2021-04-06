setup_disk:
	fallocate -l 32M hdd.dsk
	sudo losetup /dev/loop0 hdd.dsk
	sudo mkfs.minix -3 /dev/loop0
	sudo mount /dev/loop0 /mnt
	echo "Hello, this is my first file on Minix 3's filesystem" | sudo tee /mnt/hello.txt
	stat /mnt/hello.txt
	sudo sync /mnt

unmount_disk:
	sudo umount /mnt
	sudo losetup -d /dev/loop0

mount_disk:
	sudo losetup /dev/loop0 hdd.dsk
	sudo mount /dev/loop0 /mnt
