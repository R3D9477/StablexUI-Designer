package rn.stablex.designer;

import sys.io.File;
import haxe.io.Path;
import sys.FileSystem;

import openfl.Lib;
import openfl.display.*;
import openfl.events.Event;
import openfl.events.MouseEvent;
import openfl.events.KeyboardEvent;

import ru.stablex.ui.RTXml;
import ru.stablex.ui.UIBuilder;
import ru.stablex.ui.skins.*;
import ru.stablex.ui.widgets.*;
import ru.stablex.ui.events.WidgetEvent;

import com.hurlant.crypto.extra.UUID;
import com.hurlant.crypto.prng.Random;

import systools.Dialogs;
import tjson.TJSON;
import rn.TjsonStyleCl;
import rn.typext.hlp.FileSystemHelper;

using Lambda;
using StringTools;
using rn.typext.ext.XmlExtender;
using rn.typext.ext.IterExtender;
using rn.typext.ext.StringExtender;

class MainWindow extends Sprite {
	private var origCwd:String;
	
	//-----------------------------------------------------------------------------------------------
	// setup main window
	
	public function new () : Void {
		super();
		
		this.stage.align = StageAlign.TOP_LEFT;
		this.stage.scaleMode = StageScaleMode.NO_SCALE;
		
		//-----------------------------------------------------------------------------------------------
		// set current workdir
		
		this.origCwd = Sys.getCwd();
		
		Sys.setCwd(Path.directory(FileSystem.fullPath(
			#if neko
				neko.vm.Module.local().name
			#elseif cpp
				Sys.executablePath()
			#end
		)));
		
		//-----------------------------------------------------------------------------------------------
		// load designer's window size and position
		
		var configPath:String =
			Path.withExtension(FileSystem.fullPath(
				#if neko
					neko.vm.Module.local().name
				#elseif cpp
					Sys.executablePath()
				#end
			), "json");
		
		var configData:Dynamic = FileSystem.exists(configPath) ? haxe.Json.parse(File.getContent(configPath)) : {
			x: Lib.application.window.x,
			y: Lib.application.window.y,
			width: Lib.application.window.width,
			height: Lib.application.window.height
		};
		
		Lib.application.window.resize(configData.width, configData.height);
		Lib.application.window.move(configData.x, configData.y);
		
		//-----------------------------------------------------------------------------------------------
		// save designer's window size and position
		
		Lib.current.stage.application.window.onMove.add(function (x:Float, y:Float) {
			configData.x = x;
			configData.y = y;
		});
		
		Lib.current.stage.application.window.onResize.add(function (width:Int, height:Int) {
			configData.width = width;
			configData.height = height;
		});
		
		Lib.current.stage.application.onExit.add(function (code:Int)
			File.saveContent(configPath, TJSON.encode(configData, new TjsonStyleCl()))
		);
		
		//-----------------------------------------------------------------------------------------------
		// load designer's ui
		
		MainWindowInstance.setupInstance();
		
		//-----------------------------------------------------------------------------------------------
		// root
		
		MainWindowInstance.mainWnd.addEventListener(MouseEvent.MOUSE_DOWN, function (e:MouseEvent) {
			MainWindowInstance.wgtPropWnd.hide();
			MainWindowInstance.wgtEditPropWnd.hide();
		});
		
		//-----------------------------------------------------------------------------------------------
		// main menu
		
		MainWindowInstance.newGuiBtn.addEventListener(MouseEvent.CLICK, this.onNewXmlBtnClick);
		MainWindowInstance.loadGuiBtn.addEventListener(MouseEvent.CLICK, this.onLoadXmlBtnClick);
		MainWindowInstance.saveGuiBtn.addEventListener(MouseEvent.CLICK, this.onSaveXmlBtnClick);
		
		//-----------------------------------------------------------------------------------------------
		// on change current gui name
		
		MainWindowInstance.guiName.addEventListener(Event.CHANGE, this.onChangeGuiName);
		
		//-----------------------------------------------------------------------------------------------
		// on choose openfl project
		
		MainWindowInstance.chooseProject.addEventListener(MouseEvent.CLICK, this.onChooseOpenflProject);
		MainWindowInstance.chooseSrcDirPath.addEventListener(MouseEvent.CLICK, this.onChooseSrcDirPath);
		MainWindowInstance.chooseInstancePath.addEventListener(MouseEvent.CLICK, this.onChooseInstancePath);
		
		//-----------------------------------------------------------------------------------------------
		// load presets
		
		System.wgtPresetsMap = new Map<String, PresetInfo>();
		
		MainWindowInstance.presetsList.addEventListener(WidgetEvent.CHANGE, this.onSelectPreset);
		MainWindowInstance.presetsList.options = [
			for (presetName in FileSystem.readDirectory(FileSystem.fullPath("presets"))) {
				var dir:String = Path.join([FileSystem.fullPath("presets"), presetName]);
				
				var presetData:PresetInfo = TJSON.parse(File.getContent(Path.join([dir, "preset.json"])));
				presetData.dir = dir;
				
				var presetXml:Xml = System.parseXml(File.getContent(Path.join([dir, presetData.xml]))).getByXpath("//Defaults");
				
				if (presetXml.nodeName != null)
					System.wgtPresetsMap.set(presetName, presetData);
				
				[presetName.toTitleCase(), presetName];
			}
		];
		
		//-----------------------------------------------------------------------------------------------
		// load suits
		
		System.wgtSuitsMap = new Map<String, SuitInfo>();
		
		for (suitName in FileSystem.readDirectory(FileSystem.fullPath("suits"))) {
			var dir:String = Path.join([FileSystem.fullPath("suits"), suitName]);
			
			var suitData:SuitInfo = TJSON.parse(File.getContent(Path.join([dir, "suit.json"])));
			suitData.dir = dir;
			
			var suitXml:Xml = System.parseXml(File.getContent(Path.join([dir, suitData.xml]))).getByXpath("//Skins");
			
			if (suitXml.nodeName != null) {
				for (x in suitXml.elements()) {
					var si:SkinInfo = SkinParser.parse(x);
					UIBuilder.skins.set(si.name, function () : Skin return si.skin);
				}
				
				System.wgtSuitsMap.set(suitName, suitData);
			}
		}
		
		//-----------------------------------------------------------------------------------------------
		// on change main window size
		
		MainWindowInstance.guiWidth.addEventListener(Event.CHANGE, this.onChangeMainWindowSize);
		MainWindowInstance.guiHeight.addEventListener(Event.CHANGE, this.onChangeMainWindowSize);
		
		//-----------------------------------------------------------------------------------------------
		// load wgt-instance templates
		
		MainWindowInstance.guiInstanceTemplate.addEventListener(WidgetEvent.CHANGE, function (e:WidgetEvent) : Void System.guiSettings.guiInstanceTemplate = MainWindowInstance.guiInstanceTemplate.value);
		MainWindowInstance.guiInstanceTemplate.options = [for (instTemplateFile in FileSystem.readDirectory(FileSystem.fullPath("instances"))) [Path.withoutExtension(instTemplateFile), instTemplateFile]];
		
		//-----------------------------------------------------------------------------------------------
		// load frames
		
		MainWindowInstance.framesList.addEventListener(WidgetEvent.CHANGE, this.onSelectFrame);
		MainWindowInstance.framesList.options = [for (dir in FileSystem.readDirectory(FileSystem.fullPath("frames"))) [dir.toTitleCase(), dir]];
		
		//-----------------------------------------------------------------------------------------------
		// load widget groups
		
		MainWindowInstance.wlSelectBtn.addEventListener(WidgetEvent.CHANGE, function (e:MouseEvent) if (MainWindowInstance.wlSelectBtn.selected) System.selWgtData = null);
		
		MainWindowInstance.wgtGroupsLst.addEventListener(WidgetEvent.CHANGE, this.onSelectWgtsGroup);
		MainWindowInstance.wgtGroupsLst.options = [for (dir in FileSystem.readDirectory(FileSystem.fullPath("widgets"))) [dir.toTitleCase(), dir]];
		
		//-----------------------------------------------------------------------------------------------
		// on select widget from widget's list on properties panel
		
		MainWindowInstance.guiWgtsList.addEventListener(WidgetEvent.CHANGE, this.onSelectWgtFromList);
		
		//-----------------------------------------------------------------------------------------------
		// widget's properties map
		
		System.wgtPropsMap = new Map<String, WgtPropInfo>();
		
		for (wgtGrpDir in FileSystem.readDirectory(FileSystem.fullPath("widgets")))
			for (dir in FileSystem.readDirectory(Path.join([FileSystem.fullPath("widgets"), wgtGrpDir]))) {
				var wgtData:Dynamic = TJSON.parse(File.getContent(Path.join([FileSystem.fullPath("widgets"), wgtGrpDir, dir, "widget.json"])));
				
				if (wgtData.properties != null)
					if (wgtData.properties.length > 0)
						System.wgtPropsMap.set(wgtData.className, { name: wgtData.title, properties: wgtData.properties });
			}
		
		//-----------------------------------------------------------------------------------------------
		// load widget's skins map
		
		System.wgtSkinsMap = new Map<String, WgtPropInfo>();
		
		for (skinDir in FileSystem.readDirectory(FileSystem.fullPath("skins"))) {
			var skinData:Dynamic = TJSON.parse(File.getContent(Path.join([FileSystem.fullPath("skins"), skinDir, "skin.json"])));
			
			if (skinData.properties != null)
				if (skinData.properties.length > 0)
					System.wgtSkinsMap.set(skinData.className, { name: skinData.title, properties: skinData.properties });
		}
		
		//-----------------------------------------------------------------------------------------------
		// main window mouse events
		
		MainWindowInstance.wgtMainWndContainer.addEventListener(MouseEvent.MOUSE_UP, System.onMoveWgtMouseUp);
		MainWindowInstance.wgtMainWndContainer.addEventListener(MouseEvent.MOUSE_MOVE, System.onMoveWgtMouseMove);
		MainWindowInstance.wgtMainWndContainer.parent.addEventListener(MouseEvent.MOUSE_UP, System.onMoveWgtMouseUp);
		MainWindowInstance.wgtMainWndContainer.parent.addEventListener(MouseEvent.MOUSE_MOVE, System.onMoveWgtMouseMove);
		MainWindowInstance.wgtMainWndContainer.parent.parent.addEventListener(MouseEvent.MOUSE_UP, System.onMoveWgtMouseUp);
		MainWindowInstance.wgtMainWndContainer.parent.parent.addEventListener(MouseEvent.MOUSE_MOVE, System.onMoveWgtMouseMove);
		
		//-----------------------------------------------------------------------------------------------
		// widget's properties menu
		
		MainWindowInstance.showWgtPropsBtn.addEventListener(MouseEvent.CLICK, this.showWgtPropsBtnClick);
		MainWindowInstance.wgtAddPropBtn.addEventListener(MouseEvent.CLICK, this.wgtAddPropBtnClick);
		MainWindowInstance.showEditWgtPropBtn.addEventListener(MouseEvent.CLICK, this.showEditWgtPropBtnClick);
		MainWindowInstance.editPropValueSaveBtn.addEventListener(MouseEvent.CLICK, this.editPropValueSaveClick);
		MainWindowInstance.deleteWgtPropBtn.addEventListener(MouseEvent.CLICK, this.deleteWgtPropBtnClick);
		
		//-----------------------------------------------------------------------------------------------
		// xml source
		
		MainWindowInstance.xmlSource.parent.addEventListener(WidgetEvent.RESIZE, this.onXmlSourceResize);
		
		if (MainWindowInstance.xmlSource.label.multiline)
			MainWindowInstance.xmlSource.addEventListener(KeyboardEvent.KEY_UP, this.onXmlSourceChange);
		
		MainWindowInstance.xmlSource.addEventListener(MouseEvent.CLICK, function (e:MouseEvent) e.stopPropagation());
		MainWindowInstance.xmlSource.addEventListener(MouseEvent.MOUSE_UP, function (e:MouseEvent) e.stopPropagation());
		MainWindowInstance.xmlSource.addEventListener(MouseEvent.MOUSE_DOWN, function (e:MouseEvent) e.stopPropagation());
		MainWindowInstance.xmlSource.addEventListener(MouseEvent.MOUSE_MOVE, function (e:MouseEvent) e.stopPropagation());
		
		MainWindowInstance.xmlSource.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_UP));
		
		MainWindowInstance.xmlWrap.addEventListener(MouseEvent.CLICK, this.onXmlWrapChange);
		MainWindowInstance.xmlExtOpen.addEventListener(MouseEvent.CLICK, this.onXmlExtOpen);
		MainWindowInstance.xmlReloadFile.addEventListener(MouseEvent.MOUSE_UP, this.onXmlReloadFile);
		
		//-----------------------------------------------------------------------------------------------
		// initialize new project
		
		MainWindowInstance.newGuiBtn.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
		
		//-----------------------------------------------------------------------------------------------
		// load arguments
		
		for (arg in Sys.args())
			if (FileSystem.exists(arg))
				if (Path.extension(arg).toLowerCase() == "xml") {
					if (System.loadUiFromFile(FileSystem.fullPath(arg)))
						MainWindowInstance.tabDesigner.title.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
					break;
				}
		
		//-----------------------------------------------------------------------------------------------
		// designer tabs
		
		MainWindowInstance.designerTabs.addEventListener(WidgetEvent.CHANGE, this.onSelectTab);
		
		//-----------------------------------------------------------------------------------------------
		// show designer's window
		
		MainWindowInstance.mainWnd.show();
	}
	
	//-----------------------------------------------------------------------------------------------
	// main menu
	
	function onNewXmlBtnClick (e:MouseEvent) : Void {
		System.uiDirPath = null;
		System.uiXmlPath = null;
		
		System.frameXml = null;
		System.frameData = null;
		System.guiElementsXml = null;
		
		System.wgtUiXmlMap = new Map<{}, Xml>();
		System.selWgtData = null;
		
		System.moveWgt = null;
		System.moveWgtY = 0;
		System.moveWgtX = 0;
		
		System.selWgt = null;
		
		System.selWgtProp = null;
		System.selPropName = "";
		
		MainWindowInstance.xmlSource.text = "";
		
		System.guiSettings = {
			guiUuid: UUID.generateRandom(new Random()).toString(),
			guiName: "",
			wgtSrcAct: 0,
			project: "",
			srcDir: "",
			makeInstance: false,
			guiInstanceTemplate: "Default.hx",
			guiInstancePath: "",
			rootName: "",
			preset: "default",
			frameTemplate: "default",
			guiWidth: 0,
			guiHeight: 0,
			fixedWindowSize: false
		}
		
		System.refreshGuiSettings();
		
		MainWindowInstance.wgtGroupsLst.value = MainWindowInstance.wgtGroupsLst.options[0];
		MainWindowInstance.wgtGroupsLst.dispatchEvent(new WidgetEvent(WidgetEvent.CHANGE));
	}
	
	function onLoadXmlBtnClick (e:MouseEvent) : Void {
		var oFiles:Array<String> = Dialogs.openFile("Open Xml UI", "Load UI from exists Xml file.", { count: 1,  descriptions: ["StablexUI XML files"], extensions: ["*.xml"] });
		
		if (oFiles != null)
			if (System.loadUiFromFile(oFiles[0]))
				Dialogs.message("neko-systools", "UI was succefully loaded from Xml!", false);
			else
				Dialogs.message("neko-systools", "UI was not loaded from Xml!", true);
	}
	
	function onSaveXmlBtnClick (e:MouseEvent) : Void {
		var sFile:String = System.uiXmlPath > "" ? System.uiXmlPath : Dialogs.saveFile("Save Xml UI", "Save UI to Xml file.", Path.removeTrailingSlashes(System.uiDirPath > "" ? System.uiDirPath : this.origCwd), { count: 1,  descriptions: ["XML files"], extensions: ["*.xml"] });
		
		if (sFile > "") {
			if (Path.extension(sFile).toLowerCase() != "xml")
				sFile += ".xml";
			
			var oldInstancePath:String = System.guiSettings.guiInstancePath;
			
			if (System.saveUiToFile(sFile)) {
				if (!SourceControl.checkStablexUILib())
					Dialogs.message("neko-systools", "StablexUI library was not defined in project!", true);
				
				if (System.guiSettings.makeInstance) {
					SourceControl.clearWgtSources();
					
					if (SourceControl.makeInstance())
						SourceControl.setInstanceInitHxFlag(oldInstancePath);
					else
						Dialogs.message("neko-systools", "Instance was not generated!", true);
				}
				
				if (!SourceControl.embedAssets())
					Dialogs.message("neko-systools", "Some assets has not been embedded!", true);
				
				SourceControl.clearWgtSources();
				
				if (!MainWindowInstance.wgtSrcActNoth.selected)
					if (!SourceControl.registerWgtSources(MainWindowInstance.wgtSrcActCopy.selected, MainWindowInstance.wgtSrcDirPath.text))
						Dialogs.message("neko-systools", "Some sources was not registered!", true);
				
				Dialogs.message("neko-systools", "UI was succefully saved to Xml!", false);
			}
			else
				Dialogs.message("neko-systools", "UI was not saved to Xml!", true);
		}
	}
	
	//-----------------------------------------------------------------------------------------------
	// tabs
	
	function onSelectTab (e:WidgetEvent) : Void {
		if (MainWindowInstance.designerTabs.activeTab().name == "tabDesigner") {
			System.loadUiFromXml(System.parseXml(MainWindowInstance.xmlSource.text).firstElement());
			System.selectWgtFromList(0); // select first widget from list
		}
		
		MainWindowInstance.xmlSource.text = System.printXml(System.guiElementsXml, "   ");
	}
	
	//-----------------------------------------------------------------------------------------------
	// tab Project
	
	function onChooseOpenflProject (e:MouseEvent) : Void {
		var oFiles:Array<String> = Dialogs.openFile("Select OpenFL/Lime project", "", { count: 1,  descriptions: ["OpenFL/Lime XML files"], extensions: ["*.xml"] });
		
		if (oFiles != null) {
			MainWindowInstance.projectPath.text = oFiles[0];
			
			var projXml:Xml = Xml.parse(File.getContent(MainWindowInstance.projectPath.text));
			var firstSrc:String = projXml.getByXpath("//project/source").get("path");
			
			if (!FileSystem.exists(firstSrc))
				firstSrc = Path.join([Path.directory(MainWindowInstance.projectPath.text), firstSrc]);
			
			if (MainWindowInstance.wgtSrcDirPath.text == "")
				MainWindowInstance.wgtSrcDirPath.text = firstSrc;
			
			if (MainWindowInstance.guiInstancePath.text == "") {
				MainWindowInstance.guiInstancePath.text = Path.join([
					firstSrc,
					Path.join(projXml.getByXpath("//project/app").get("main").split(".").slice(0, -1)),
					MainWindowInstance.guiName.text.toTitleCase() + "Instance.hx"
				]);
				
				MainWindowInstance.wgtMakeUiInst.selected = true;
			}
		}
	}
	
	function onChooseSrcDirPath (e:MouseEvent) : Void {
		var srcDir:String = Dialogs.folder("Select sources dir", "Select directory of current OpenFL/Lime project");
		
		if (srcDir > "")
			MainWindowInstance.wgtSrcDirPath.text = srcDir;
	}
	
	function onChooseInstancePath (e:MouseEvent) : Void {
		var oFiles:Array<String> = Dialogs.openFile("Select instance file", "", { count: 1,  descriptions: ["Haxe Source Code"], extensions: ["*.hx"] });
		
		if (oFiles != null)
			MainWindowInstance.guiInstancePath.text = oFiles[0];
	}
	
	function onChangeGuiName (e:WidgetEvent) : Void {
		if (MainWindowInstance.guiName.text == "")
			MainWindowInstance.guiName.text = 'main_${MainWindowInstance.mainWnd.name}';
		
		System.guiSettings.guiName = MainWindowInstance.guiName.text;
		
		MainWindowInstance.mainWnd.name = System.guiSettings.guiName;
		System.frameXml.set("name", "'" + System.guiSettings.guiName + "'");
	}
	
	function onChangeMainWindowSize (e:Event) : Void {
		if (MainWindowInstance.guiWidth.text == "")
			MainWindowInstance.guiWidth.text = "0";
		
		cast(MainWindowInstance.wgtMainWndContainer, Widget).w = Std.parseFloat(MainWindowInstance.guiWidth.text);
		
		if (MainWindowInstance.guiHeight.text == "")
			MainWindowInstance.guiHeight.text = "0";
		
		cast(MainWindowInstance.wgtMainWndContainer, Widget).h = Std.parseFloat(MainWindowInstance.guiHeight.text);
	}
	
	function onSelectPreset (e:WidgetEvent) : Void {
		System.guiSettings.preset = MainWindowInstance.presetsList.value;
		
		var preset:PresetInfo = System.wgtPresetsMap.get(System.guiSettings.preset);
		StablexUIMod.rtDefaults = System.parseXml(File.getContent(Path.join([preset.dir, preset.xml])));
	}
	
	function onSelectFrame (e:WidgetEvent) : Void {
		System.frameData = TJSON.parse(File.getContent(Path.join([FileSystem.fullPath("frames"), MainWindowInstance.framesList.value, "window.json"])));
		
		MainWindowInstance.guiWidth.text = Std.string(System.frameData.width);
		MainWindowInstance.guiHeight.text = Std.string(System.frameData.height);
		MainWindowInstance.guiHeight.dispatchEvent(new Event(Event.CHANGE));
		
		MainWindowInstance.fixedWindowSize.selected = System.frameData.fixedSize;
		
		System.loadUiFromXml(System.parseXml(File.getContent(Path.join([FileSystem.fullPath("frames"), MainWindowInstance.framesList.value, System.frameData.xml]))).firstElement());
	}
	
	//-----------------------------------------------------------------------------------------------
	// tab Designer
	
	function onSelectWgtsGroup (e:WidgetEvent) : Void {
		MainWindowInstance.wlSelectBtn.selected = true;
		MainWindowInstance.wgtsLst.freeChildren(true);
		
		for (dir in FileSystem.readDirectory(FileSystem.fullPath(Path.join(["widgets", MainWindowInstance.wgtGroupsLst.value])))) {
			dir = FileSystem.fullPath(Path.join(["widgets", MainWindowInstance.wgtGroupsLst.value, dir]));
			
			var wgtData:WgtInfo = TJSON.parse(File.getContent(Path.join([dir, "widget.json"])));
			wgtData.dir = dir;
			wgtData.ico = Path.join([dir, wgtData.ico]);
			
			if (!Path.isAbsolute(wgtData.xml))
				wgtData.xml = Path.join([dir, wgtData.xml]);
			
			if (wgtData.bin != null) {
				#if neko
					if (FileSystem.exists(wgtData.bin.neko.escNull()))
						if (!Path.isAbsolute(wgtData.bin.neko))
							wgtData.bin.neko = Path.join([dir, wgtData.bin.neko]);
				#end
			}
			
			var tip:Tip = new Tip();
			tip.text = wgtData.title;
			
			var ico:Bmp = new Bmp();
			ico.src = wgtData.ico.replace(Path.addTrailingSlash(Sys.getCwd()), ""); // wgtData.ico; workaround
			ico.refresh();
			
			var wgtSelector:Radio = UIBuilder.buildFn("XmlGui/WgtSelector.xml")();
			wgtSelector.tip = tip;
			wgtSelector.ico = ico;
			wgtSelector.onPress = function (e:MouseEvent) : Void System.selWgtData = wgtData;
			
			MainWindowInstance.wgtsLst.addChild(wgtSelector);
		}
	}
	
	function onSelectWgtFromList (e:WidgetEvent) : Void {
		if (System.guiElementsWgt != null) {
			var wgt:Widget = System.guiElementsWgt.getChild(MainWindowInstance.guiWgtsList.value);
			
			if (wgt != System.moveWgt) {
				MainWindowInstance.wlSelectBtn.selected = true;
				
				wgt.dispatchEvent(new MouseEvent(MouseEvent.MOUSE_DOWN));
				wgt.dispatchEvent(new MouseEvent(MouseEvent.MOUSE_UP));
			}
		}
	}
	
	function showWgtPropsBtnClick (e:MouseEvent) : Void {
		MainWindowInstance.wgtEditPropWnd.hide();
		
		if (System.selWgt != null) {
			MainWindowInstance.wgtPropWnd.top = e.stageY + 5;
			MainWindowInstance.wgtPropWnd.left = e.stageX - MainWindowInstance.wgtPropWnd.w - 5;
			
			MainWindowInstance.wgtPropTypesLst.clearEvent(WidgetEvent.CHANGE);
			MainWindowInstance.wgtPropTypesLst.addEventListener(WidgetEvent.CHANGE, function (e:WidgetEvent) {
				var nullToEmptyArr = function (data:Dynamic) : Dynamic return data == null ? { properties: new Array<String>() } : data;
				
				var proplst:Array<Array<String>> = nullToEmptyArr(System.wgtPropsMap.get(MainWindowInstance.wgtPropTypesLst.value)).properties
					.filter(function (wgtProperty:String) : Bool return !System.selWgtProps.exists(wgtProperty))
					.map(function (wgtProperty:String) : Array<String> return [ System.propNameMap(wgtProperty), wgtProperty ])
					.concat(nullToEmptyArr(System.wgtSkinsMap.get(MainWindowInstance.wgtPropTypesLst.value)).properties
						.map(function (skinProperty:String) : String return "skin:" + MainWindowInstance.wgtPropTypesLst.value.split(".").pop() + "-" + skinProperty)
						.filter(function (skinProperty:String) : Bool return !System.selWgtProps.exists(skinProperty))
						.map(function (skinProperty:String) : Array<String> return [skinProperty , skinProperty])
					);
				
				MainWindowInstance.wgtPropNamesLst.options = proplst.length > 0 ? proplst : [ [ "", null ] ];
				
				MainWindowInstance.wgtPropNamesLst.value = MainWindowInstance.wgtPropNamesLst.options[0];
				MainWindowInstance.wgtPropNamesLst.dispatchEvent(new WidgetEvent(WidgetEvent.CHANGE));
			});
			
			MainWindowInstance.wgtPropTypesLst.options = System.wgtPropsMap.keys().array()
				.filter(function (wgtPropClass:String) : Bool return Std.is(System.selWgt, Type.resolveClass(wgtPropClass)))
				.map(function (wgtPropClass) : Array<String> return [ System.wgtPropsMap.get(wgtPropClass).name, wgtPropClass ])
				.concat(System.wgtSkinsMap.keys().array()
					.filter(function (skinPropClass:String) : Bool return Reflect.getProperty(System.selWgt, "skin") == null || Std.is(Reflect.getProperty(System.selWgt, "skin"), Type.resolveClass(skinPropClass)))
					.map(function (skinPropClass) : Array<String> return [ "skin:" + skinPropClass.split(".").pop(), skinPropClass ])
				);
			
			MainWindowInstance.wgtPropTypesLst.value = MainWindowInstance.wgtPropTypesLst.options[0];
			MainWindowInstance.wgtPropTypesLst.dispatchEvent(new WidgetEvent(WidgetEvent.CHANGE));
			
			MainWindowInstance.wgtPropWnd.show();
		}
		
		e.stopPropagation();
	}
	
	function wgtAddPropBtnClick (e:MouseEvent) : Void {
		if (System.selWgt != null && MainWindowInstance.wgtPropNamesLst.value != null) {
			var prop:Dynamic = Reflect.getProperty(System.selWgt, MainWindowInstance.wgtPropNamesLst.value);
			var value:String = Std.string(prop).replace(",", ".");
			
			if (Std.is(prop, String))
				value = "'" + value + "'";
			
			System.wgtUiXmlMap.get(System.selWgt).set(MainWindowInstance.wgtPropNamesLst.value, value);
			System.addPropRow(MainWindowInstance.wgtPropNamesLst.value, value);
			
			var proplst:Array<Array<Dynamic>> = MainWindowInstance.wgtPropNamesLst.options;
			proplst.remove(MainWindowInstance.wgtPropNamesLst.value);
			
			MainWindowInstance.wgtPropNamesLst.options = proplst.length > 0 ? proplst : [ [ "", null ] ];
			
			MainWindowInstance.wgtPropTypesLst.value = MainWindowInstance.wgtPropTypesLst.options[0];
			MainWindowInstance.wgtPropTypesLst.dispatchEvent(new WidgetEvent(WidgetEvent.CHANGE));
		}
		
		e.stopPropagation();
	}
	
	function showEditWgtPropBtnClick (e:MouseEvent) : Void {
		MainWindowInstance.wgtPropWnd.hide();
		
		if (System.selPropName > "" && System.selWgt != null) {
			MainWindowInstance.wgtEditPropWnd.top = e.stageY + 5;
			MainWindowInstance.wgtEditPropWnd.left = e.stageX - MainWindowInstance.wgtPropWnd.w - 5;
			
			var ownerInfo:Dynamic = System.getPropertyOwner(System.selWgt, System.selPropName);
			
			MainWindowInstance.editPropName.text = System.propNameMap(System.selPropName);
			MainWindowInstance.editPropType.text = Std.string(Type.typeof(Reflect.getProperty(ownerInfo.propOwner, ownerInfo.propName)));
			MainWindowInstance.editPropValue.text = System.wgtUiXmlMap.get(System.selWgt).get(System.selPropName);
			
			MainWindowInstance.wgtEditPropWnd.show();
		}
		
		e.stopPropagation();
	}
	
	function editPropValueSaveClick (e:MouseEvent) : Void {
		if (System.selWgt != null && System.selPropName > "" && MainWindowInstance.editPropValue.text > "") {
			System.setWgtProperty(System.selWgt, System.selPropName, MainWindowInstance.editPropValue.text);
			MainWindowInstance.wgtEditPropWnd.hide();
		}
		
		e.stopPropagation();
	}
	
	function deleteWgtPropBtnClick (e:MouseEvent) : Void {
		MainWindowInstance.wgtEditPropWnd.hide();
		MainWindowInstance.wgtPropWnd.hide();
		
		if (System.selWgt != null && System.selWgtProp != null && MainWindowInstance.editPropValue.text > "") {
			System.setWgtProperty(System.selWgt, System.selPropName, System.getGuiObjDefaultPropValue(System.selWgt, System.selPropName));
			System.selWgtProps.remove(System.selPropName);
			System.wgtUiXmlMap.get(System.selWgt).remove(System.selPropName);
			System.selWgtProp.parent.removeChild(System.selWgtProp);
			
			System.selWgtProp = null;
			System.selPropName = "";
		}
		
		e.stopPropagation();
	}
	
	//-----------------------------------------------------------------------------------------------
	// tab Xml: widget's xml source
	
	function onXmlSourceResize (e:WidgetEvent) : Void {
		MainWindowInstance.xmlSource.w = Math.max(cast(MainWindowInstance.xmlSource.parent, Scroll).w, MainWindowInstance.xmlSource.label.textWidth + cast(MainWindowInstance.xmlSource.parent, Scroll).vBar.w + 5);
		MainWindowInstance.xmlSource.h = Math.max(cast(MainWindowInstance.xmlSource.parent, Scroll).h, MainWindowInstance.xmlSource.label.textHeight + cast(MainWindowInstance.xmlSource.parent, Scroll).hBar.h + 5);
	}
	
	function onXmlSourceChange (e:KeyboardEvent) : Void
		MainWindowInstance.xmlSource.parent.dispatchEvent(new WidgetEvent(WidgetEvent.RESIZE));
	
	function onXmlWrapChange (e:MouseEvent) : Void
		MainWindowInstance.xmlSource.label.wordWrap = MainWindowInstance.xmlWrap.selected;
	
	function onXmlExtOpen (e:MouseEvent) : Void {
		if (FileSystem.exists(System.uiXmlPath.escNull()))
			FileSystemHelper.execUrl(FileSystem.fullPath(System.uiXmlPath));
		else
			Dialogs.message("neko-systools", "UI must be saved to file!", true);
	}
	
	function onXmlReloadFile (e:MouseEvent) : Void {
		if (FileSystem.exists(System.uiXmlPath.escNull())) {
			var xml:Xml = System.parseXml(File.getContent(FileSystem.fullPath(System.uiXmlPath)));
			MainWindowInstance.xmlSource.text = System.printXml(xml.getByXpath("//GuiElements"), "   ");
		}
		else
			Dialogs.message("neko-systools", "UI must be saved to file!", true);
	}
}
