StablexUI-Designer
=========================

Graphical designer (builder) for [GUI](https://en.wikipedia.org/wiki/Graphical_user_interface) library [StablexUI](https://github.com/RealyUniqueName/StablexUI).<br/>
(current version is in progress and very unstable!)

###Current features:<br/>
* generic
	* build a new gui
	* load existing gui from xml-file
	* save gui to xml-file
* themes
	* change defaults from presets collection
* windows settings
	* change frames of current window from templates collection
	* change size of current window
* designing
	* use all standard widgets from ["ru.stablex.ui.widgets.*"](https://github.com/RealyUniqueName/StablexUI/tree/master/src/ru/stablex/ui/widgets)
	* use all standard skins from ["ru.stablex.ui.skins.*"](https://github.com/RealyUniqueName/StablexUI/tree/master/src/ru/stablex/ui/skins)
	* allow to evaluate [haXe](https://haxe.org/)-expression and use result as value for property of widget
* customizing
	* allow to use custom templates of frame (root widget)
	* allow to use custom widgets
	* allow to use custom skins
	* allow to use custom defaults
* easy integration with openfl/lime project
	* auto-insertion of instruction '<haxelib name="stablexui">' (if not exist) to current openfl/lime project
	* auto-registration of selected presets (defaults) in current openfl/lime project
	* auto-insertion of assets to current openfl/lime project
	* auto-insertion of sources path of custom widgets to current openfl/lime project
	* auto-generation of file with declaration of objects for widgets with names (to easy access to widgets from source code)
* allow to edit raw xml of current gui manually
	* allow to run saved xml file in external editor "on the fly"
	* allow to force reload xml from saved file

###Requirements:<br/>
* [haxe](https://haxe.org) 3.2.1 or later
* [hxcpp](https://github.com/HaxeFoundation/hxcpp)
* [lime](https://github.com/openfl/lime)
* [openfl](https://github.com/openfl/openfl)
* [hscript](https://github.com/HaxeFoundation/hscript)
* [stablexui](https://github.com/RealyUniqueName/StablexUI)
* [systools](https://github.com/waneck/systools.git)
* [haxe-crypto](https://github.com/soywiz/haxe-crypto)
* [tjson](https://github.com/martamius/TJSON)
* [tjsonStyleCl](https://github.com/r3d9u11/haxe-tjsonStyleCl)
* [typext](https://github.com/r3d9u11/haxe-typext)

###Install:<br/>

#####Linux (32-bit):<br/>
```bash
curl -H 'Cache-Control: no-cache' https://raw.githubusercontent.com/r3d9u11/StablexUI-Designer/master/Install-Linux.sh | bash
```

#####Linux (64-bit):<br/>
```bash
curl -H 'Cache-Control: no-cache' https://raw.githubusercontent.com/r3d9u11/StablexUI-Designer/master/Install-Linux64.sh | bash
```
