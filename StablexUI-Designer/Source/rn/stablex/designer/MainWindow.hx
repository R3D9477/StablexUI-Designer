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

import systools.Dialogs;
import tjson.TJSON;
import rn.TjsonStyleCl;
import rn.typext.hlp.FileSystemHelper;

using Lambda;
using StringTools;
using rn.typext.ext.StringExtender;
using rn.typext.ext.IterExtender;

class MainWindow extends Sprite {
	//-----------------------------------------------------------------------------------------------
	// setup main window
	
	public function new () : Void {
		super();
		
		this.stage.align = StageAlign.TOP_LEFT;
		this.stage.scaleMode = StageScaleMode.NO_SCALE;
		
		//-----------------------------------------------------------------------------------------------
		// set current workdir
		
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
		
		var configData:Dynamic = FileSystem.exists(configPath) ? TJSON.parse(File.getContent(configPath)) : {
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
		
		//-----------------------------------------------------------------------------------------------
		// load presets
		
		MainWindowInstance.presetsList.addEventListener(Event.CHANGE, this.onSelectPreset);
		MainWindowInstance.presetsList.options = MainWindowInstance.presetsList.options.concat([for (preset in FileSystem.readDirectory(FileSystem.fullPath("presets"))) [Path.withoutExtension(preset).toTitleCase(), preset]]);
		
		//-----------------------------------------------------------------------------------------------
		// load suits
		
		System.wgtSuitsMap = new Map<String, SuitInfo>();
		
		for (suit in FileSystem.readDirectory(FileSystem.fullPath("suits"))) {
			var suitDir:String = Path.join([FileSystem.fullPath("suits"), suit]);
			
			var suitData:SuitInfo = TJSON.parse(File.getContent(Path.join([suitDir, "suit.json"])));
			var suitXml:Xml = System.parseXml(File.getContent(Path.join([suitDir, suitData.xml]))).firstElement();
			
			if (suitXml.nodeName == "Skins") {
				for (x in suitXml.elements()) {
					var si:SkinInfo = SkinParser.parse(x);
					UIBuilder.skins.set(si.name, function () : Skin return si.skin);
				}
				
				System.wgtSuitsMap.set(suit, suitData);
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
		
		MainWindowInstance.framesList.addEventListener(WidgetEvent.CHANGE, this.onSelectMainWindow);
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
			for (wgtDir in FileSystem.readDirectory(Path.join([FileSystem.fullPath("widgets"), wgtGrpDir]))) {
				var wgtData:Dynamic = TJSON.parse(File.getContent(Path.join([FileSystem.fullPath("widgets"), wgtGrpDir, wgtDir, "widget.json"])));
				
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
		System.guiSettings = {
			guiUuid: "",
			guiName: "",
			wgtSrcAct: 0,
			project: "",
			srcDir: "",
			makeInstance: false,
			guiInstanceTemplate: "",
			guiInstancePath: "",
			rootName: "",
			preset: "",
			frameTemplate: "",
			guiWidth: 0,
			guiHeight: 0,
			fixedWindowSize: false
		}
		
		System.uiDirPath = null;
		System.uiXmlPath = null;
		
		MainWindowInstance.xmlSource.text = "";
		
		System.frameXml = null;
		System.frameData = null;
		System.guiElementsXml = null;
		
		System.wgtUiXmlMap = new Map<{}, Xml>();
		System.selWgtData = null;
		
		System.moveWgt = null;
		System.moveWgtY = 0;
		System.moveWgtX = 0;
		
		MainWindowInstance.guiInstanceTemplate.value = "Default.hx"; //MainWindowInstance.guiInstanceTemplate.options[0];
		MainWindowInstance.guiInstanceTemplate.dispatchEvent(new WidgetEvent(WidgetEvent.CHANGE));
		
		MainWindowInstance.presetsList.value = null; //MainWindowInstance.presetsList.options[0];
		
		MainWindowInstance.framesList.value = "default"; //MainWindowInstance.framesList.options[0];
		MainWindowInstance.framesList.dispatchEvent(new WidgetEvent(WidgetEvent.CHANGE));
		
		MainWindowInstance.wgtGroupsLst.value = "default inputs"; //MainWindowInstance.wgtGroupsLst.options[0];
		MainWindowInstance.wgtGroupsLst.dispatchEvent(new WidgetEvent(WidgetEvent.CHANGE));
		
		System.selWgt = null;
		
		System.selWgtProp = null;
		System.selPropName = "";
		
		MainWindowInstance.guiName.text = "";
		MainWindowInstance.guiName.dispatchEvent(new WidgetEvent(WidgetEvent.CHANGE));
	}
	
	function onLoadXmlBtnClick (e:MouseEvent) : Void {
		var oFiles:Array<String> = Dialogs.openFile("Open Xml UI", "Load UI from exists Xml file.", { count: 1,  descriptions: ["StablexUI XML files"], extensions: ["*.xml"] }, false);
		
		if (oFiles != null)
			if (System.loadUiFromFile(oFiles[0]))
				Dialogs.message("neko-systools", "UI was succefully loaded from Xml!", false);
			else
				Dialogs.message("neko-systools", "UI was not loaded from Xml!", true);
	}
	
	function onSaveXmlBtnClick (e:MouseEvent) : Void {
		var sFile:String = System.uiXmlPath > "" ? System.uiXmlPath : Dialogs.saveFile("Save Xml UI", "Save UI to Xml file.", System.uiDirPath > "" ? System.uiDirPath : Sys.getCwd(), { count: 1,  descriptions: ["XML files"], extensions: ["*.xml"] });
		
		if (sFile > "")
			if (System.saveUiToFile(sFile))
				Dialogs.message("neko-systools", "UI was succefully saved to Xml!", false);
			else
				Dialogs.message("neko-systools", "UI was not saved to Xml!", true);
	}
	
	//-----------------------------------------------------------------------------------------------
	// tabs
	
	function onSelectTab (e:WidgetEvent) : Void {
		if (MainWindowInstance.designerTabs.activeTab().name == "tabDesigner") {
			System.loadUiFromXml(System.parseXml(MainWindowInstance.xmlSource.text).firstElement());
			System.selectFirstWidget();
		}
		
		MainWindowInstance.xmlSource.text = System.printXml(System.guiElementsXml, "   ");
	}
	
	//-----------------------------------------------------------------------------------------------
	// tab Project
	
	function onChooseOpenflProject (e:MouseEvent) : Void {
		var oFiles:Array<String> = Dialogs.openFile("Select OpenFL/Lime project", "", { count: 1,  descriptions: ["OpenFL/Lime XML files"], extensions: ["*.xml"] }, false);
		
		if (oFiles != null)
			MainWindowInstance.projectPath.text = oFiles[0];
	}
	
	function onChangeGuiName (e:WidgetEvent) : Void {
		if (MainWindowInstance.guiName.text == "")
			MainWindowInstance.guiName.text = MainWindowInstance.mainWnd.name;
		
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
		//...
		//...
		//...
	}
	
	function onSelectMainWindow (e:WidgetEvent) : Void {
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
		
		for (wgtDir in FileSystem.readDirectory(FileSystem.fullPath(Path.join(["widgets", MainWindowInstance.wgtGroupsLst.value])))) {
			wgtDir = Path.join(["widgets", MainWindowInstance.wgtGroupsLst.value, wgtDir]);
			
			var wgtData:WgtDataInfo = TJSON.parse(File.getContent(FileSystem.fullPath(Path.join([wgtDir, "widget.json"]))));
			wgtData.ico = Path.join([wgtDir, wgtData.ico]);
			
			if (!Path.isAbsolute(wgtData.xml))
				wgtData.xml = FileSystem.fullPath(Path.join([wgtDir, wgtData.xml]));
			
			if (wgtData.bin > "")
				if (!Path.isAbsolute(wgtData.bin))
					wgtData.bin = FileSystem.fullPath(Path.join([wgtDir, wgtData.bin]));
			
			var tip:Tip = new Tip();
			tip.text = wgtData.title;
			
			var ico:Bmp = new Bmp();
			ico.src = wgtData.ico;
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
		
		e.stopPropagation();
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
			System.wgtUiXmlMap.get(System.selWgt).set(MainWindowInstance.wgtPropNamesLst.value, Std.string(Reflect.getProperty(System.selWgt, MainWindowInstance.wgtPropNamesLst.value)).replace(",", "."));
			System.addPropRow(MainWindowInstance.wgtPropNamesLst.value, Std.string(Reflect.getProperty(System.selWgt, MainWindowInstance.wgtPropNamesLst.value)).replace(",", "."));
			
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
		if (System.selPropName > "" && System.selWgt != null && MainWindowInstance.editPropValue.text > "") {
			System.setWgtProperty(System.selWgt, System.selPropName, MainWindowInstance.editPropValue.text);
			MainWindowInstance.wgtEditPropWnd.hide();
		}
		
		e.stopPropagation();
	}
	
	function deleteWgtPropBtnClick (e:MouseEvent) : Void {
		MainWindowInstance.wgtEditPropWnd.hide();
		MainWindowInstance.wgtPropWnd.hide();
		
		if (System.selWgt != null && MainWindowInstance.editPropValue.text > "") {
			System.setWgtProperty(System.selWgt, System.selPropName, null);
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
	
	function onXmlSourceChange (e:KeyboardEvent) : Void { // workaround for TextField https://github.com/openfl/openfl/issues/1254
		if (e.keyCode == 13) {
			MainWindowInstance.xmlSource.text = MainWindowInstance.xmlSource.text.substring(0, MainWindowInstance.xmlSource.label.caretIndex) + "\n" + MainWindowInstance.xmlSource.text.substring(MainWindowInstance.xmlSource.label.caretIndex, MainWindowInstance.xmlSource.text.length);
			MainWindowInstance.xmlSource.label.setSelection(MainWindowInstance.xmlSource.label.caretIndex + 1, MainWindowInstance.xmlSource.label.caretIndex + 1);
		}
		
		MainWindowInstance.xmlSource.parent.dispatchEvent(new WidgetEvent(WidgetEvent.RESIZE));
	}
}
