#!/bin/bash
cd ../StablexUI-Designer
rm -rf Export
lime build linux -64 -cpp
cd Export/linux64/cpp/release/bin
./StablexUI-Designer ../../../../../../Test/XmlGui/Test.xml
