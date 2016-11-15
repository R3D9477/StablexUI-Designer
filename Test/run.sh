#!/bin/bash
cd ../StablexUI-Designer
rm -rf Export
lime build linux -64 -neko
cd Export/linux64/neko/release/bin
cp ../obj/ApplicationMain.n ./StablexUI-Designer.n
neko StablexUI-Designer.n ../../../../../../Test/XmlGui/Test.xml
