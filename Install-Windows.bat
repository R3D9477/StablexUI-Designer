:::::::::::::::::::::::::::::::::::::
:: INSTALL NEEDED HAXELIB PACKAGES ::
:::::::::::::::::::::::::::::::::::::

haxelib upgrade

haxelib -notimeout install format
haxelib -notimeout install hxcpp
haxelib -notimeout install hvm
haxelib -notimeout install actuate

haxelib -notimeout install lime
haxelib -notimeout install lime-tools
haxelib -notimeout install lime-samples
haxelib run lime setup

haxelib -notimeout install openfl
haxelib -notimeout install openfl-tools
haxelib -notimeout install openfl-samples
haxelib -notimeout install openfl-native
haxelib run openfl setup

haxelib -notimeout install haxe-crypto

haxelib -notimeout git stablexui https://github.com/RealyUniqueName/StablexUI.git

haxelib -notimeout git systools https://github.com/waneck/systools.git
haxelib -notimeout git haxity https://github.com/r3d9u11/haxe-haxity.git

haxelib -notimeout git typext https://github.com/r3d9u11/haxe-typext.git
haxelib -notimeout git dataTree https://github.com/r3d9u11/haxe-dataTree.git

::::::::::::::::::::::::::::::::::::::::
:: DOWNLOAD LATEST STABLEXUI-DESIGNER ::
::::::::::::::::::::::::::::::::::::::::

git clone https://github.com/r3d9u11/StablexUI-Designer.git

::::::::::::::::::::::::::::::::::::::::
:: COMPILE AND RUN STABLEXUI-DESIGNER ::
::::::::::::::::::::::::::::::::::::::::

cd ".\StablexUI-Designer\StablexUI-Designer\Assets\widgets\custom\custom widget"
haxe compile.hxml

cd "..\..\..\.."
openfl test windows -neko
