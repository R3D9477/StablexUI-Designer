#!/bin/bash
cd ../StablexUI-Designer
rm -rf Export
openfl build linux -64 -cpp
cd Export/linux64/cpp/release/bin
./StablexUI-Designer ../../../../../../Test/XmlGui/Test.xml
