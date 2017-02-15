#!/bin/bash

#################################
# INSTALL NEEDED LINUX PACKAGES #
#################################

sudo add-apt-repository ppa:haxe/releases -y
sudo apt-get update

sudo apt-get install g++ git haxe neko-dev -y

if [ ! -f ~/.haxelib ]; then
	echo ~/.haxelib-repo > ~/.haxelib
fi

DLG_BUILDER="unknown"

if [ $DESKTOP_SESSION = "ubuntu" ] || \
	[ $DESKTOP_SESSION = "mate" ] || \
	[ $DESKTOP_SESSION = "gnome" ] || \
	[ $DESKTOP_SESSION = "cinnamon" ] || \
	[ $DESKTOP_SESSION = "lxde" ] || \
	[ $DESKTOP_SESSION = "xfce" ]; then
	DLG_BUILDER="zenity"
	sudo apt-get install zenity
elif [ $DESKTOP_SESSION = "kde" ]; then
	DLG_BUILDER="kdialog"
	sudo apt-get install kdialog
elif [ $DESKTOP_SESSION = "" ]; then
	DLG_BUILDER="dialog"
	sudo apt-get install dialog
fi

###################################
# INSTALL NEEDED HAXELIB PACKAGES #
###################################

echo "y" | haxelib upgrade

echo "y" | haxelib -notimeout install format
echo "y" | haxelib -notimeout install hxcpp
echo "y" | haxelib -notimeout install hvm
echo "y" | haxelib -notimeout install actuate

echo "y" | haxelib -notimeout install lime
echo "y" | haxelib -notimeout install lime-tools
echo "y" | haxelib -notimeout install lime-samples
bash -c 'echo "y" | haxelib run lime setup'

echo "y" | haxelib -notimeout install openfl
echo "y" | haxelib -notimeout install openfl-tools
echo "y" | haxelib -notimeout install openfl-samples
echo "y" | haxelib -notimeout install openfl-native
bash -c 'echo "y" | haxelib run openfl setup'

echo "y" | haxelib -notimeout install haxe-crypto

echo "y" | haxelib -notimeout git stablexui https://github.com/RealyUniqueName/StablexUI.git

echo "y" | haxelib -notimeout git systools https://github.com/waneck/systools.git
echo "y" | haxelib -notimeout git haxity https://github.com/r3d9u11/haxe-haxity.git

echo "y" | haxelib -notimeout git typext https://github.com/r3d9u11/haxe-typext.git
echo "y" | haxelib -notimeout git dataTree https://github.com/r3d9u11/haxe-dataTree.git

######################################
# DOWNLOAD LATEST STABLEXUI-DESIGNER #
######################################

git clone https://github.com/r3d9u11/StablexUI-Designer.git

######################################
# COMPILE AND RUN STABLEXUI-DESIGNER #
######################################

PLATFORM=32
TARGET="neko"
OUTDIR="linux"

if [ $(uname -m) = "x86_64" ]; then
	PLATFORM=64
fi

for i in "$@"
	do
	if [ $i = "-32" ]; then
		PLATFORM=32
	elif [ $i = "-64" ]; then
		PLATFORM=64
	elif [ $i = "-neko" ]; then
		TARGET="neko"
	elif [ $i = "-cpp" ]; then
		TARGET="cpp"
	fi
done

OUTDIR="linux"

if [ $PLATFORM -eq 64 ]; then
	OUTDIR=$OUTDIR'64'
fi

OUTDIR=$OUTDIR'/'$TARGET

echo "DLG_BUILDER = ${DLG_BUILDER}"
echo "PLATFORM = ${PLATFORM}"
echo "TARGET = ${TARGET}"
echo "OUTDIR = ${OUTDIR}"

cd "./StablexUI-Designer/StablexUI-Designer"
rm -rf "./Export"

openfl test linux -$PLATFORM -$TARGET
