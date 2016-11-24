#!/bin/bash

#################################
# INSTALL NEEDED LINUX PACKAGES #
#################################

sudo apt-get install git

###################################
# INSTALL NEEDED HAXELIB PACKAGES #
###################################

haxelib install format
haxelib install hxcpp
haxelib install hvm
haxelib install actuate

haxelib install lime
haxelib install lime-tools
haxelib install lime-samples
haxelib run lime setup

haxelib install openfl
haxelib install openfl-tools
haxelib install openfl-samples
haxelib install openfl-native
haxelib run openfl setup

haxelib install ihx
haxelib install tjson
haxelib install haxe-crypto
haxelib git systools https://github.com/waneck/systools.git

haxelib git stablexui https://github.com/RealyUniqueName/StablexUI.git

haxelib git typext https://github.com/r3d9u11/haxe-typext.git
haxelib git libmodbus https://github.com/r3d9u11/haxe-libmodbus.git
haxelib git tjsonStyleCl https://github.com/r3d9u11/haxe-tjsonStyleCl.git
haxelib git dataTree https://github.com/r3d9u11/haxe-dataTree.git

######################################
# DOWNLOAD LATEST STABLEXUI-DESIGNER #
######################################

git clone https://github.com/r3d9u11/StablexUI-Designer.git

######################################
# COMPILE AND RUN STABLEXUI-DESIGNER #
######################################

cd "./StablexUI-Designer/StablexUI-Designer"

rm -rf "./Export"
openfl build linux -64 -neko

cd "./Export/linux64/neko/release/bin"
cp "../obj/ApplicationMain.n" "./StablexUI-Designer.n"

neko "StablexUI-Designer.n"
