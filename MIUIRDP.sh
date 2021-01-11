#!/bin/bash

#Variables

PARTITIONS=("system" "product")
payload_extractor="tools/update_payload_extractor/extract.py"
dattoimg="tools/sdat2img.py"
LOCALDIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
outdir="$LOCALDIR/cache"
tmpdir="$outdir/tmp"
#############################################################

usage() {
    echo "Usage: $0 <Firmware Type> [Path to Firmware]"
    echo -e "\tFirmware Type! = MIUI"
    echo -e "\tPath to Firmware!"
}

if [ "$1" == "" ]; then
    echo "Enter all needed parameters"
    usage
    exit 1
fi

echo "This must be used only for MIUI Android 11 devices with Dynamic Partition .
      Create Temp and out dir"
	mkdir -p "$tmpdir"
	mkdir -p "$outdir"

unzip $2 -d $tmpdir &> /dev/null
echo "Extracting Required species . . . . "
        unzip $tmpdir/*.zip -d $tmpdir &> /dev/null
	    brotli -d $tmpdir/system.new.dat.br 
        brotli -d $tmpdir/product.new.dat.br
        brotli -d $tmpdir/system_ext.new.dat.br
        python $dattoimg $tmpdir/system.transfer.list $tmpdir/system.new.dat $tmpdir/system.img
        python $dattoimg $tmpdir/product.transfer.list $tmpdir/product.new.dat $tmpdir/product.img
        python $dattoimg $tmpdir/system_ext.transfer.list $tmpdir/system_ext.new.dat $tmpdir/system_ext.img
        mv $tmpdir/system.img $outdir/system-old.img
	    mv $tmpdir/product.img $outdir/product.img
        mv $tmpdir/system_ext.img $outdir/system_ext.img
        rm -rf $tmpdir

echo "Making bottle wothout water . . . . "
dd if=/dev/zero of=$outdir/system.img bs=1k count=6M
mkfs.ext4 $outdir/system.img
tune2fs -c0 -i0 $outdir/system.img

echo "Mounting System Images . . . . "
	mkdir system
	mkdir system-old
	mount -o loop $outdir/system.img system/
	mount -o ro $outdir/system-old.img system-old/
	echo "  "

echo "Copying Files . . . . "
	cp -v -r -p system-old/* system/ &> /dev/null
	sync
	umount system-old
	rm $outdir/system-old.img
	rm -rf system/product
	ln -s system/product system/product
    	rm -rf system/system/product
    	mkdir system/system/product/

echo "Merging product.img "
	sudo mkdir $outdir/product
	mount -o ro $outdir/product.img $outdir/product/
	cp -v -r -p $outdir/product/* system/system/product/ &> /dev/null
	sync
	umount $outdir/product
	rmdir $outdir/product/
	rm $outdir/product.img

echo "Merging system_ext.img "
	    sudo mkdir $outdir/system_ext
	    mount -o ro $outdir/system_ext.img $outdir/system_ext/
	    rm -rf system/system_ext
	    rm -rf system/system/system_ext
	    mkdir system/system/system_ext
	    ln -s system/system_ext system/system_ext
	    cp -v -r -p $outdir/system_ext/* system/system/system_ext/ &> /dev/null
	    sync
	    umount $outdir/system_ext
	    rmdir $outdir/system_ext/
	    rm $outdir/system_ext.img

echo "Finalising "
	mkdir out
	rm -rf system-old/
echo "Please finish creating GSI using make.sh script"
