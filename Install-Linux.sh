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

if [ $DESKTOP_SESSION = "ubuntu" ] || \
	[ $DESKTOP_SESSION = "mate" ] || \
	[ $DESKTOP_SESSION = "gnome" ] || \
	[ $DESKTOP_SESSION = "cinnamon" ] || \
	[ $DESKTOP_SESSION = "lxde" ] || \
	[ $DESKTOP_SESSION = "xfce" ]; then
	sudo apt-get install zenity
elif [ $DESKTOP_SESSION = "kde" ]; then
	sudo apt-get install kdialog
elif [ $DESKTOP_SESSION = "" ]; then
	sudo apt-get install dialog
fi

###################################
# INSTALL NEEDED HAXELIB PACKAGES #
###################################

echo "y" | haxelib upgrade

echo "y" | haxelib install format
echo "y" | haxelib install hxcpp
echo "y" | haxelib install hvm
echo "y" | haxelib install actuate

echo "y" | haxelib install lime
echo "y" | haxelib install lime-tools
echo "y" | haxelib install lime-samples
bash -c 'echo "y" | haxelib run lime setup'

echo "y" | haxelib install openfl
echo "y" | haxelib install openfl-tools
echo "y" | haxelib install openfl-samples
echo "y" | haxelib install openfl-native
bash -c 'echo "y" | haxelib run openfl setup'

echo "y" | haxelib install tjson
echo "y" | haxelib install haxe-crypto

echo "y" | haxelib git stablexui https://github.com/RealyUniqueName/StablexUI.git

echo "y" | haxelib git systools https://github.com/waneck/systools.git
echo "y" | haxelib git haxity https://github.com/r3d9u11/haxe-haxity.git

echo "y" | haxelib git typext https://github.com/r3d9u11/haxe-typext.git
echo "y" | haxelib git tjsonStyleCl https://github.com/r3d9u11/haxe-tjsonStyleCl.git
echo "y" | haxelib git dataTree https://github.com/r3d9u11/haxe-dataTree.git

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

echo "PLATFORM = ${PLATFORM}"
echo "TARGET = ${TARGET}"
echo "OUTDIR = ${OUTDIR}"

cd "./StablexUI-Designer/StablexUI-Designer"
rm -rf "./Export"

openfl test linux -$PLATFORM -$TARGET
