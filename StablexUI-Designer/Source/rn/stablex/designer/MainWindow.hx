package rn.stablex.designer;

import sys.io.File;
import haxe.io.Path;
import sys.FileSystem;

import openfl.Lib;
import openfl.display.*;
import openfl.events.Event;
import openfl.events.MouseEvent;
import openfl.events.KeyboardEvent;

import ru.stablex.ui.UIBuilder;
import ru.stablex.ui.skins.*;
import ru.stablex.ui.widgets.*;
import ru.stablex.ui.events.WidgetEvent;

import tjson.TJSON;
import rn.TjsonStyleCl;
import rn.typext.hlp.FileSystemHelper;

import rn.haxity.Haxity;

using Lambda;
using StringTools;
using rn.typext.ext.XmlExtender;
using rn.typext.ext.IterExtender;
using rn.typext.ext.ClassExtender;
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
		// workaround for haxe < 3.4.0
		
		var programPath:String =
			#if haxe_340
				Sys.propgramPath();
			#else
				switch (Sys.systemName().toLowerCase()) {
					case "linux":
						#if neko
							Path.join([Suid.getCwd(), "StablexUI-Designer.n"]);
						#elseif cpp
							Sys.executablePath();
						#end
					default:
						Sys.executablePath();
				};
			#end
		
		this.origCwd = Suid.getCwd();
		Sys.setCwd(Path.directory(programPath));
		
		//-----------------------------------------------------------------------------------------------
		// load designer's window size and position
		
		var configPath:String = Path.withExtension(programPath, "json");
		
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
		// initialize system
		
		System.resetSettings();
		MainWindowInstance.setupInstance();
		StablexUIMod.setRtxmlMod();
		
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
		MainWindowInstance.projectPath.addEventListener(Event.CHANGE, this.onChangeOpenflProject);
		
		//-----------------------------------------------------------------------------------------------
		// on change parent widget
		
		MainWindowInstance.chooseParentGui.addEventListener(MouseEvent.CLICK, this.onChooseParentGuiPath);
		MainWindowInstance.parentGuiPath.addEventListener(Event.CHANGE, this.onChangeParentGuiPath);
		
		//-----------------------------------------------------------------------------------------------
		// load wgt. instances
		
		MainWindowInstance.guiInstanceTemplate.options = [for (instTemplateFile in FileSystem.readDirectory(Suid.fullPath("instances"))) [Path.withoutExtension(instTemplateFile), instTemplateFile]];
		MainWindowInstance.guiInstanceTemplate.addEventListener(WidgetEvent.CHANGE, function (e:WidgetEvent) : Void System.guiSettings.guiInstanceTemplate = MainWindowInstance.guiInstanceTemplate.value);
		
		MainWindowInstance.chooseInstancePath.addEventListener(MouseEvent.CLICK, this.onChooseInstancePath);
		MainWindowInstance.guiInstancePath.addEventListener(Event.CHANGE, this.onChangeInstancePath);
		
		//-----------------------------------------------------------------------------------------------
		// on choose src directory
		
		MainWindowInstance.chooseSrcDirPath.addEventListener(MouseEvent.CLICK, this.onChooseSrcDirPath);
		
		//-----------------------------------------------------------------------------------------------
		// load ext. classes
		
		System.extClsMap = new Map<String, WgtPropInfo>();
		
		for (clsFile in FileSystem.readDirectory(Suid.fullPath("extcls"))) {
			var extClsData:Dynamic = TJSON.parse(File.getContent(Path.join([Suid.fullPath("extcls"), clsFile])));
			System.extClsMap.set(extClsData.className, { name: extClsData.title, properties: extClsData.properties });
		}
		
		//-----------------------------------------------------------------------------------------------
		// load presets
		
		System.wgtPresetsMap = new Map<String, PresetInfo>();
		
		MainWindowInstance.presetsList.options = [
			for (presetName in FileSystem.readDirectory(Suid.fullPath("presets"))) {
				var dir:String = Path.join([Suid.fullPath("presets"), presetName]);
				
				var presetData:PresetInfo = TJSON.parse(File.getContent(Path.join([dir, "preset.json"])));
				presetData.dir = dir;
				
				var presetXml:Xml = SuidXml.parseXml(File.getContent(Path.join([dir, presetData.xml]))).getByXpath("//Defaults");
				
				if (presetXml.nodeName != null)
					System.wgtPresetsMap.set(presetName, presetData);
				
				[presetName.toTitleCase(), presetName];
			}
		];
		
		MainWindowInstance.presetsList.addEventListener(WidgetEvent.CHANGE, this.onSelectPreset);
		
		//-----------------------------------------------------------------------------------------------
		// on change main window size
		
		MainWindowInstance.guiWidth.addEventListener(Event.CHANGE, this.onChangeMainWindowSize);
		MainWindowInstance.guiHeight.addEventListener(Event.CHANGE, this.onChangeMainWindowSize);
		
		//-----------------------------------------------------------------------------------------------
		// load suits
		
		System.wgtSuitsMap = new Map<String, SuitInfo>();
		
		for (suitName in FileSystem.readDirectory(Suid.fullPath("suits"))) {
			var dir:String = Path.join([Suid.fullPath("suits"), suitName]);
			
			var suitData:SuitInfo = TJSON.parse(File.getContent(Path.join([dir, "suit.json"])));
			suitData.dir = dir;
			
			var suitXml:Xml = SuidXml.parseXml(File.getContent(Path.join([dir, suitData.xml]))).getByXpath("//Skins");
			
			if (suitXml.nodeName != null) {
				for (x in suitXml.elements()) {
					var si:SkinInfo = SkinParser.parse(x);
					UIBuilder.skins.set(si.name, function () : Skin return si.skin);
				}
				
				System.wgtSuitsMap.set(suitName, suitData);
			}
		}
		
		//-----------------------------------------------------------------------------------------------
		// load frames
		
		MainWindowInstance.framesList.options = [
			for (dir in FileSystem.readDirectory(Suid.fullPath("frames")))
				[TJSON.parse(File.getContent(Path.join([Suid.fullPath("frames"), dir, "frame.json"]))).title, dir]
		];
		
		MainWindowInstance.framesList.addEventListener(WidgetEvent.CHANGE, this.onSelectFrame);
		
		//-----------------------------------------------------------------------------------------------
		// load widget groups
		
		MainWindowInstance.wlSelectBtn.addEventListener(WidgetEvent.CHANGE, function (e:MouseEvent) if (MainWindowInstance.wlSelectBtn.selected) System.selWgtData = null);
		
		MainWindowInstance.wgtGroupsLst.options = [for (dir in FileSystem.readDirectory(Suid.fullPath("widgets"))) [dir.toTitleCase(), dir]];
		MainWindowInstance.wgtGroupsLst.addEventListener(WidgetEvent.CHANGE, this.onSelectWgtsGroup);
		
		//-----------------------------------------------------------------------------------------------
		// on select widget from widget's list on properties panel
		
		MainWindowInstance.guiWgtsList.addEventListener(WidgetEvent.CHANGE, this.onSelectWgtFromList);
		
		//-----------------------------------------------------------------------------------------------
		// widget's properties map
		
		System.wgtPropsMap = new Map<String, WgtPropInfo>();
		
		for (wgtGrpDir in FileSystem.readDirectory(Suid.fullPath("widgets")))
			for (dir in FileSystem.readDirectory(Path.join([Suid.fullPath("widgets"), wgtGrpDir]))) {
				var wgtData:Dynamic = TJSON.parse(File.getContent(Path.join([Suid.fullPath("widgets"), wgtGrpDir, dir, "widget.json"])));
				
				if (wgtData.properties != null)
					if (wgtData.properties.length > 0)
						System.wgtPropsMap.set(wgtData.className, { name: wgtData.title, properties: wgtData.properties });
			}
		
		//-----------------------------------------------------------------------------------------------
		// load widget's skins map
		
		System.wgtSkinsMap = new Map<String, WgtPropInfo>();
		
		for (skinDir in FileSystem.readDirectory(Suid.fullPath("skins"))) {
			var skinData:Dynamic = TJSON.parse(File.getContent(Path.join([Suid.fullPath("skins"), skinDir, "skin.json"])));
			
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
		MainWindowInstance.wgtPropTypesLst.addEventListener(WidgetEvent.CHANGE, this.wgtAddPropTypeChanged);
		MainWindowInstance.wgtPropNamesLst.addEventListener(WidgetEvent.CHANGE, this.wgtAddPropNameChanged);
		MainWindowInstance.wgtAddPropRefresh.addEventListener(MouseEvent.CLICK, this.wgtAddPropRefresh);
		MainWindowInstance.wgtAddPropBack.addEventListener(MouseEvent.CLICK, this.wgtAddPropBack);
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
		// initialize RT-system
		
		HxExpr.init();
		
		//-----------------------------------------------------------------------------------------------
		// initialize new project
		
		MainWindowInstance.newGuiBtn.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
		
		//-----------------------------------------------------------------------------------------------
		// load arguments
		
		for (arg in Sys.args()) {
			arg = Suid.escPath(arg); // workaround for Windows
			
			if (FileSystem.exists(arg))
				if (Path.extension(arg).toLowerCase() == "xml") {
					if (System.loadUiFromFile(Suid.fullPath(arg)))
						MainWindowInstance.tabDesigner.title.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
					break;
				}
		}
		
		//-----------------------------------------------------------------------------------------------
		// designer tabs
		
		MainWindowInstance.designerTabs.addEventListener(WidgetEvent.CHANGE, this.onSelectTab);
		
		//-----------------------------------------------------------------------------------------------
		// show designer's window
		
		MainWindowInstance.mainWnd.show();
		MainWindowInstance.projScroll.refresh();
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
		
		System.resetSettings();
		System.refreshGuiSettings();
		
		MainWindowInstance.wgtGroupsLst.value = MainWindowInstance.wgtGroupsLst.options[0];
		MainWindowInstance.wgtGroupsLst.dispatchEvent(new WidgetEvent(WidgetEvent.CHANGE));
	}
	
	function onLoadXmlBtnClick (e:MouseEvent) : Void {
		//var defDir:String = Path.removeTrailingSlashes(StringExtender.isNullOrEmpty(System.uiDirPath) ? this.origCwd : System.uiDirPath);
		var oFile:String = Haxity.openFile("Open Xml UI"); // ["StablexUI XML files"], ["*.xml"]
		
		if (!StringExtender.isNullOrEmpty(oFile))
			if (System.loadUiFromFile(Suid.escPath(oFile)))
				Haxity.info("Open UI", "UI was succefully loaded from Xml!");
			else
				Haxity.error("Open UI", "UI was not loaded from Xml!");
	}
	
	function onSaveXmlBtnClick (e:MouseEvent) : Void {
		var defDir:String = Path.removeTrailingSlashes(StringExtender.isNullOrEmpty(System.uiDirPath) ? this.origCwd : System.uiDirPath);
		
		var saveFunc:String->Void = function (sFile:String) {
			if (!StringExtender.isNullOrEmpty(sFile)) {
				sFile = Suid.escPath(sFile);
				
				if (Path.extension(sFile).toLowerCase() != "xml")
					sFile += ".xml";
				
				var oldInstancePath:String = System.guiSettings.guiInstancePath;
				
				if (System.saveUiToFile(sFile)) {
					if (!StringExtender.isNullOrEmpty(System.guiSettings.project))
						if (!SourceControl.checkStablexUILib())
							Haxity.warning("Save UI", "StablexUI library was not registered in project!");
					
					if (System.guiSettings.makeInstance) {
						SourceControl.clearWgtSources();
						
						if (SourceControl.makeInstance()) {
							if (!SourceControl.setInstanceInitHxFlag())
								Haxity.warning("Save UI", "Instance was generated but not registered in project!");
						}
						else
							Haxity.warning("Save UI", "Instance was not generated!");
					}
					
					if (!StringExtender.isNullOrEmpty(System.guiSettings.project)) {
						if (StringExtender.isNullOrEmpty(System.guiSettings.parentGuiPath))
							if (!SourceControl.setWindow())
								Haxity.warning("Save UI", "Some properties of window has not been set!");
						
						if (System.guiSettings.embedAssets)
							if (!SourceControl.embedAssets())
								Haxity.warning("Save UI", "Some assets has not been embedded!");
					}
					
					if (System.guiSettings.wgtSrcAct != 0)
						if (!SourceControl.registerWgtSources(MainWindowInstance.wgtSrcActCopy.selected, MainWindowInstance.wgtSrcDirPath.text))
							Haxity.warning("Save UI", "Some sources was not registered!");
					
					if (!StringExtender.isNullOrEmpty(System.guiSettings.parentGuiPath))
						if (System.guiSettings.parentGuiAutoreg)
							if (!SourceControl.registerParentXml())
								Haxity.warning("Save UI", "Can't register at parent XML!");
					
					Haxity.info("Save UI", "UI was succefully saved to Xml!");
				}
				else
					Haxity.error("Save UI", "UI was not saved to Xml!");
			}
		}
		
		if (!StringExtender.isNullOrEmpty(System.uiXmlPath))
			saveFunc(System.uiXmlPath);
		else
			saveFunc(Haxity.saveFile("Save Xml UI")); // ["XML files"], ["*.xml"]
	}
	
	//-----------------------------------------------------------------------------------------------
	// tabs
	
	function onSelectTab (e:WidgetEvent) : Void {
		if (MainWindowInstance.designerTabs.activeTab().name == "tabDesigner") {
			System.loadUiFromXml(SuidXml.parseXml(MainWindowInstance.xmlSource.text).firstElement());
			System.selectWgtFromList(0); // select first widget from list
		}
		
		if (MainWindowInstance.designerTabs.activeTab().name == "tabProject")
			MainWindowInstance.projScroll.refresh();
		
		MainWindowInstance.xmlSource.text = SuidXml.printXml(System.guiElementsXml, "   ");
	}
	
	//-----------------------------------------------------------------------------------------------
	// tab Project
	
	function onChangeGuiName (e:WidgetEvent) : Void {
		if (MainWindowInstance.guiName.text == "")
			MainWindowInstance.guiName.text = 'main_${MainWindowInstance.mainWnd.name}';
		
		System.guiSettings.guiName = MainWindowInstance.guiName.text;
		
		MainWindowInstance.mainWnd.name = System.guiSettings.guiName;
		System.frameXml.set("name", "'" + System.guiSettings.guiName + "'");
	}
	
	function onChooseOpenflProject (e:MouseEvent) : Void {
		//var defDir:String = Path.removeTrailingSlashes(StringExtender.isNullOrEmpty(System.uiDirPath) ? this.origCwd : System.uiDirPath);
		var oFile:String = Haxity.openFile("Select OpenFL/Lime project"); // ["OpenFL/Lime XML files"], ["*.xml"]
		
		if (!StringExtender.isNullOrEmpty(oFile))
			MainWindowInstance.projectPath.text = Suid.escPath(oFile);
	}
	
	function onChangeOpenflProject (e:WidgetEvent) : Void {
		if (FileSystem.exists(MainWindowInstance.projectPath.text.escNull())) {
			MainWindowInstance.wgtSrcActLink.selected = true;
			
			var projXml:Xml = Xml.parse(File.getContent(Suid.fullPath(System.guiSettings.project)));
			var firstSrc:String = Suid.escPath(projXml.getByXpath("//project/source").get("path"));
			
			if (!FileSystem.exists(firstSrc))
				firstSrc = Suid.escPath(Path.join([Path.directory(MainWindowInstance.projectPath.text), firstSrc]));
			
			if (StringExtender.isNullOrEmpty(MainWindowInstance.wgtSrcDirPath.text))
				MainWindowInstance.wgtSrcDirPath.text = firstSrc;
			
			System.saveUiSettingsToXml();
			
			if (StringExtender.isNullOrEmpty(MainWindowInstance.guiInstancePath.text)) {
				MainWindowInstance.guiInstancePath.text = Path.join([
					firstSrc,
					Path.join(projXml.getByXpath("//project/app").get("main").split(".").slice(0, -1)),
					MainWindowInstance.guiName.text.toTitleCase() + "Instance.hx"
				]);
				
				MainWindowInstance.wgtMakeUiInst.selected = true;
			}
		}
	}
	
	function onChooseParentGuiPath (e:MouseEvent) : Void {
		//var defDir:String = Path.removeTrailingSlashes(StringExtender.isNullOrEmpty(System.uiDirPath) ? this.origCwd : System.uiDirPath);
		var oFile:String = Haxity.openFile("Open Xml UI"); // ["StablexUI XML files"], ["*.xml"]
		
		if (!StringExtender.isNullOrEmpty(oFile)) {
			MainWindowInstance.parentGuiPath.text = oFile;
			this.onChangeParentGuiPath(null); // https://github.com/RealyUniqueName/StablexUI/issues/258
			
			System.saveUiSettingsToXml();
		}
	}
	
	function onChangeParentGuiPath (e:WidgetEvent) : Void {
		if (FileSystem.exists(MainWindowInstance.parentGuiPath.text.escNull())) {
			var parentUiSettings:GuiDataInfo = System.getUiSettings(SuidXml.parseXml(File.getContent(Suid.fullPath(MainWindowInstance.parentGuiPath.text))).firstElement());
			
			if (parentUiSettings != null) {
				MainWindowInstance.wgtMakeUiInst.selected = parentUiSettings.makeInstance;
				MainWindowInstance.guiInstanceTemplate.value = parentUiSettings.guiInstanceTemplate;
				MainWindowInstance.guiInstancePath.text = parentUiSettings.guiInstancePath;
				MainWindowInstance.guiInstanceFunction.text = parentUiSettings.guiInstanceFunction;
				
				System.saveUiSettingsToXml();
			}
			
			MainWindowInstance.parentGuiAutoreg.selected = true;
		}
	}
	
	function onChooseSrcDirPath (e:MouseEvent) : Void {
		//var defDir:String = Path.removeTrailingSlashes(StringExtender.isNullOrEmpty(System.uiDirPath) ? this.origCwd : System.uiDirPath);
		var oDir:String = Haxity.openDirectory("Select sources dir");
		
		if (!StringExtender.isNullOrEmpty(oDir)) {
			MainWindowInstance.wgtSrcDirPath.text = Suid.escPath(oDir);
			
			System.saveUiSettingsToXml();
		}
	}
	
	function onChooseInstancePath (e:MouseEvent) : Void {
		//var defDir:String = Path.removeTrailingSlashes(StringExtender.isNullOrEmpty(System.uiDirPath) ? this.origCwd : System.uiDirPath);
		var oFile:String = Haxity.saveFile("Select instance file");
		
		if (!StringExtender.isNullOrEmpty(oFile)) {
			MainWindowInstance.guiInstancePath.text = Suid.escPath(oFile);
			this.onChangeInstancePath(null); // https://github.com/RealyUniqueName/StablexUI/issues/258
			
			System.saveUiSettingsToXml();
		}
	}
	
	function onChangeInstancePath (e:WidgetEvent) : Void {
		MainWindowInstance.guiInstanceFunction.text = SourceControl.generateInstanceFunction(MainWindowInstance.guiInstancePath.text);
		
		System.saveUiSettingsToXml();
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
		StablexUIMod.rtDefaults = SuidXml.parseXml(File.getContent(Path.join([preset.dir, preset.xml])));
	}
	
	function onSelectFrame (e:WidgetEvent) : Void {
		System.frameData = TJSON.parse(File.getContent(Path.join([Suid.fullPath("frames"), MainWindowInstance.framesList.value, "frame.json"])));
		
		MainWindowInstance.guiWidth.text = Std.string(System.frameData.width);
		MainWindowInstance.guiHeight.text = Std.string(System.frameData.height);
		MainWindowInstance.guiHeight.dispatchEvent(new Event(Event.CHANGE));
		
		MainWindowInstance.wndBackground.text = Std.string(System.frameData.background);
		MainWindowInstance.wndFps.text = Std.string(System.frameData.fps);
		MainWindowInstance.wndVsync.selected = System.frameData.vsync;
		MainWindowInstance.wndBorderless.selected = System.frameData.borderless;
		MainWindowInstance.wndResizable.selected = System.frameData.resizable;
		MainWindowInstance.wndFullscreen.selected = System.frameData.fullscreen;
		MainWindowInstance.wndHardware.selected = System.frameData.hardware;
		MainWindowInstance.wndAllowShaders.selected = System.frameData.allowShaders;
		MainWindowInstance.wndRequireShaders.selected = System.frameData.requireShaders;
		MainWindowInstance.wndDepthBuffer.selected = System.frameData.depthBuffer;
		MainWindowInstance.wndStencilBuffer.selected = System.frameData.stencilBuffer;
		MainWindowInstance.wndOrientation.value = System.frameData.orientation;
		
		System.loadUiFromXml(SuidXml.parseXml(File.getContent(Path.join([Suid.fullPath("frames"), MainWindowInstance.framesList.value, System.frameData.xml]))).firstElement());
	}
	
	//-----------------------------------------------------------------------------------------------
	// tab Designer
	
	function onSelectWgtsGroup (e:WidgetEvent) : Void {
		MainWindowInstance.wlSelectBtn.selected = true;
		MainWindowInstance.wgtsLst.freeChildren(true);
		
		for (dir in FileSystem.readDirectory(Suid.fullPath(Path.join(["widgets", MainWindowInstance.wgtGroupsLst.value])))) {
			dir = Suid.fullPath(Path.join(["widgets", MainWindowInstance.wgtGroupsLst.value, dir]));
			
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
			ico.bitmapData = BitmapData.fromFile(wgtData.ico.replace(Path.addTrailingSlash(Suid.getCwd()), ""));
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
			
			PropertyBuilder.init(Type.getClass(System.selWgt));
			
			PropertyBuilder.rebuildPropTypesList();
			MainWindowInstance.wgtPropTypesLst.options = PropertyBuilder.propTypesList;
			
			MainWindowInstance.wgtPropWnd.show();
		}
		
		e.stopPropagation();
	}
	
	function wgtAddPropTypeChanged (e:Event) : Void {
		MainWindowInstance.wgtPropNamesLst.options = PropertyBuilder.rebuildPropNamesList(MainWindowInstance.wgtPropTypesLst.value);
		MainWindowInstance.wgtPropCustom.text = PropertyBuilder.tmpPpBuf;
		
		e.stopPropagation();
	}
	
	function wgtAddPropNameChanged (e:Event) : Void {
		if (PropertyBuilder.rebuildPrototype(MainWindowInstance.wgtPropNamesLst.value))
			MainWindowInstance.wgtPropTypesLst.options = PropertyBuilder.propTypesList;
		
		MainWindowInstance.wgtPropCustom.text = PropertyBuilder.tmpPpBuf;
		
		e.stopPropagation();
	}
	
	function wgtAddPropRefresh (e:MouseEvent) : Void {
		PropertyBuilder.refreshPrototype(MainWindowInstance.wgtPropCustom.text);
		MainWindowInstance.wgtPropTypesLst.options = PropertyBuilder.propTypesList;
		MainWindowInstance.wgtPropCustom.text = PropertyBuilder.tmpPpBuf;
		
		e.stopPropagation();
	}
	
	function wgtAddPropBack (e:MouseEvent) : Void {
		PropertyBuilder.backPrototype();
		MainWindowInstance.wgtPropTypesLst.options = PropertyBuilder.propTypesList;
		MainWindowInstance.wgtPropCustom.text = PropertyBuilder.tmpPpBuf;
		
		e.stopPropagation();
	}
	
	function wgtAddPropBtnClick (e:MouseEvent) : Void {
		if (System.selWgt != null && !StringExtender.isNullOrEmpty(MainWindowInstance.wgtPropCustom.text)) {
			var prop:Dynamic = Reflect.getProperty(System.selWgt, MainWindowInstance.wgtPropCustom.text);
			var value:String = Std.string(prop).replace(",", ".");
			
			if (Std.is(prop, String))
				value = "'" + value + "'";
			
			System.wgtUiXmlMap.get(System.selWgt).set(MainWindowInstance.wgtPropCustom.text, value);
			System.addPropRow(MainWindowInstance.wgtPropCustom.text, value);
		}
		
		e.stopPropagation();
	}
	
	function showEditWgtPropBtnClick (e:MouseEvent) : Void {
		MainWindowInstance.wgtPropWnd.hide();
		
		if (!StringExtender.isNullOrEmpty(System.selPropName) && System.selWgt != null) {
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
		if (System.selWgt != null && !StringExtender.isNullOrEmpty(System.selPropName) && !StringExtender.isNullOrEmpty(MainWindowInstance.editPropValue.text)) {
			System.setWgtProperty(System.selWgt, System.selPropName, MainWindowInstance.editPropValue.text);
			MainWindowInstance.wgtEditPropWnd.hide();
		}
		
		e.stopPropagation();
	}
	
	function deleteWgtPropBtnClick (e:MouseEvent) : Void {
		MainWindowInstance.wgtEditPropWnd.hide();
		MainWindowInstance.wgtPropWnd.hide();
		
		if (System.selWgt != null && System.selWgtProp != null && !StringExtender.isNullOrEmpty(MainWindowInstance.editPropValue.text)) {
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
			FileSystemHelper.execUrl(Suid.fullPath(System.uiXmlPath));
		else
			Haxity.error("Open UI", "UI must be saved to file!");
	}
	
	function onXmlReloadFile (e:MouseEvent) : Void {
		if (FileSystem.exists(System.uiXmlPath.escNull())) {
			var xml:Xml = SuidXml.parseXml(File.getContent(Suid.fullPath(System.uiXmlPath)));
			MainWindowInstance.xmlSource.text = SuidXml.printXml(xml.getByXpath("//GuiElements"), "   ");
		}
		else
			Haxity.error("Load UI", "UI must be saved to file!");
	}
}
