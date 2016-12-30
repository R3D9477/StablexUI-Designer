StablexUI-Designer
=========================

Graphical designer (builder) for [GUI](https://en.wikipedia.org/wiki/Graphical_user_interface) library [StablexUI](https://github.com/RealyUniqueName/StablexUI).<br/>
Demo-video available [here](https://youtu.be/8SPn3NZE8T4).<br/>

(wiki and the list of the plans will be soon...)<br/>

###Current features:<br/>
* generic
	* build a new gui
	* load existing gui from xml-file
	* save gui to xml-file
* themes
	* change [defaults](http://ui.stablex.ru/doc/#manual/07_Presets(Defaults).html) from [collection of presets](StablexUI-Designer/Assets/presets)
* windows settings
	* change frames of current window from templates collection
	* change size and other settings of current window (see description of tag `<window />` in [XML Format](http://www.openfl.org/learn/docs/command-line-tools/project-files/xml-format/))
* designing
	* use all standard widgets from ["ru.stablex.ui.widgets.*"](https://github.com/RealyUniqueName/StablexUI/tree/master/src/ru/stablex/ui/widgets)
	* use all standard skins from ["ru.stablex.ui.skins.*"](https://github.com/RealyUniqueName/StablexUI/tree/master/src/ru/stablex/ui/skins)
	* allow to evaluate [haXe](https://haxe.org/)-expression and use result as value for property of widget
	* allow to use an alignment of widgets to grid
* customizing
	* allow to use custom templates of frame (root widget)
	* allow to use custom widgets
	* allow to use custom skins
	* allow to use custom defaults
* easy integration with [openfl/lime project](http://www.openfl.org/learn/docs/command-line-tools/project-files/xml-format/)
	* auto-insertion of instruction `<haxelib name="stablexui">` (if not exist)
	* auto-registration of selected presets (defaults)
	* auto-insertion of assets
	* auto-insertion of sources path of custom widgets
	* auto-generation of file with declaration of objects for widgets with names (to easy access to widgets from source code)
* allow to edit raw xml of current gui manually
	* allow to run saved xml file in external editor "on the fly"
	* allow to force reload xml from saved file

###Available targets:<br/>
* [neko](http://haxe.org/doc/start/neko)
* [cpp](http://haxe.org/doc/start/cpp) (restricted)

###Requirements:<br/>
* [git-tools](https://git-scm.com/downloads)
* [haxe](https://haxe.org) 3.2.1 or later
* [neko-vm](http://nekovm.org) 2.1.0 or later
* [haxelib](https://lib.haxe.org/)-packages:
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

#####Linux (one-command installation):<br/>
* run command in terminal:
```bash
curl -H 'Cache-Control: no-cache' https://raw.githubusercontent.com/r3d9u11/StablexUI-Designer/master/Install-Linux.sh | bash
```

#####Windows:<br/>
* download and install [git-tools](https://git-scm.com/download/win)
* download and install [haxe](https://haxe.org/download/)
* download and run [installation script](https://raw.githubusercontent.com/r3d9u11/StablexUI-Designer/master/Install-Windows.bat)
