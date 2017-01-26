package rn.stablex.designer;

import sys.io.File;
import haxe.io.Path;
import sys.FileSystem;

import openfl.events.Event;
import openfl.events.MouseEvent;

import ru.stablex.*;
import ru.stablex.ui.*;
import ru.stablex.ui.skins.*;
import ru.stablex.ui.widgets.*;
import ru.stablex.ui.layouts.Row;
import ru.stablex.ui.events.WidgetEvent;

import com.hurlant.crypto.extra.UUID;
import com.hurlant.crypto.prng.Random;

import rn.haxity.Haxity;

using StringTools;
using rn.typext.ext.XmlExtender;
using rn.typext.ext.IterExtender;
using rn.typext.ext.BoolExtender;
using rn.typext.ext.StringExtender;

class System {
	public static var guiSettings:GuiDataInfo;
	
	public static var extClsMap:Map<String, WgtPropInfo>; // <class name>, <set of external classes>
	
	public static var wgtPresetsMap:Map<String, PresetInfo>; // <presets name>, <set of presets>
	public static var wgtPropsMap:Map<String, WgtPropInfo>; // <class name>, <set of properties>
	public static var wgtSuitsMap:Map<String, SuitInfo>; // <class name>, <set of suits>
	public static var wgtSkinsMap:Map<String, WgtPropInfo>; // <class name>, <set of properties>
	
	public static var wgtUiXmlMap:Map<{}, Xml>; // <widget>, <xml>
	
	public static var frameXml:Xml;
	public static var frameWgt:Widget;
	public static var frameData:FrameInfo;
	
	public static var guiElementsXml:Xml;
	public static var guiElementsWgt:Widget;
	
	public static var selWgt:Dynamic;
	public static var selWgtData:WgtInfo;
	
	public static var selWgtProp:HBox;
	public static var selWgtProps:Map<String, HBox>;
	public static var selPropName:String;
	
	public static var moveWgt:Dynamic;
	public static var moveWgtY:Float;
	public static var moveWgtX:Float;
	
	public static var uiDirPath:String;
	public static var uiXmlPath:String;
	
	//-----------------------------------------------------------------------------------------------
	// gui settings
	
	public static function resetSettings () : Void {
		System.guiSettings = {
			guiUuid: UUID.generateRandom(new Random()).toString(),
			
			guiName: "",
			project: "",
			parentGuiPath: "",
			parentGuiAutoreg: false,
			
			wgtSrcAct: 0,
			srcDir: "",
			makeInstance: false,
			guiInstanceTemplate: "Default.hx",
			guiInstancePath: "",
			guiInstanceFunction: "",
			
			preset: "default",
			embedAssets: true,
			
			frameTemplate: "main_window",
			guiWidth: 0,
			guiHeight: 0,
			
			wndBackground: "0xFFFFFF",
			wndFps: 30,
			wndVsync: false,
			wndBorderless: false,
			wndResizable: true,
			wndFullscreen: false,
			wndHardware: false,
			wndAllowShaders: false,
			wndRequireShaders: false,
			wndDepthBuffer: false,
			wndStencilBuffer: false,
			wndOrientation: 'auto',
			
			useGrid: true,
			gridSize: 10,
			gridType: 1,
			gridColor: 0xFFFFFF,
			gridBorderSize: 1
		}
	}
	
	public static function saveUiSettingsToXml (xml:Xml = null) : Void {
		if (xml == null)
			xml = System.frameXml;
		
		if (System.guiSettings == null || xml == null)
			return;
		
		for(elem in xml)
			if (elem.nodeType == Xml.XmlType.Comment)
				elem.removeSelf();
		
		System.guiSettings.guiName = MainWindowInstance.guiName.text;
		System.guiSettings.project = MainWindowInstance.projectPath.text;
		System.guiSettings.parentGuiPath = MainWindowInstance.parentGuiPath.text;
		System.guiSettings.parentGuiAutoreg = MainWindowInstance.parentGuiAutoreg.selected;
		
		if (MainWindowInstance.wgtSrcActLink.selected)
			System.guiSettings.wgtSrcAct = 1;
		else if (MainWindowInstance.wgtSrcActCopy.selected)
			System.guiSettings.wgtSrcAct = 2;
		else
			System.guiSettings.wgtSrcAct = 0;
		
		System.guiSettings.srcDir = MainWindowInstance.wgtSrcDirPath.text;
		
		System.guiSettings.makeInstance = MainWindowInstance.wgtMakeUiInst.selected;
		System.guiSettings.guiInstanceTemplate = MainWindowInstance.guiInstanceTemplate.value;
		System.guiSettings.guiInstancePath = MainWindowInstance.guiInstancePath.text;
		System.guiSettings.guiInstanceFunction = MainWindowInstance.guiInstanceFunction.text;
		
		System.guiSettings.preset = MainWindowInstance.presetsList.value;
		System.guiSettings.embedAssets = MainWindowInstance.embedAssets.selected;
		
		System.guiSettings.frameTemplate = MainWindowInstance.framesList.value;
		System.guiSettings.guiWidth = Std.parseInt(MainWindowInstance.guiWidth.text);
		System.guiSettings.guiHeight = Std.parseInt(MainWindowInstance.guiHeight.text);
		
		System.guiSettings.wndBackground = MainWindowInstance.wndBackground.text;
		System.guiSettings.wndFps = Std.parseInt(MainWindowInstance.wndFps.text);
		System.guiSettings.wndVsync = MainWindowInstance.wndVsync.selected;
		System.guiSettings.wndBorderless = MainWindowInstance.wndBorderless.selected;
		System.guiSettings.wndResizable = MainWindowInstance.wndResizable.selected;
		System.guiSettings.wndFullscreen = MainWindowInstance.wndFullscreen.selected;
		System.guiSettings.wndHardware = MainWindowInstance.wndHardware.selected;
		System.guiSettings.wndAllowShaders = MainWindowInstance.wndAllowShaders.selected;
		System.guiSettings.wndRequireShaders = MainWindowInstance.wndRequireShaders.selected;
		System.guiSettings.wndDepthBuffer = MainWindowInstance.wndDepthBuffer.selected;
		System.guiSettings.wndStencilBuffer = MainWindowInstance.wndStencilBuffer.selected;
		System.guiSettings.wndOrientation = MainWindowInstance.wndOrientation.value;
		
		System.guiSettings.useGrid = MainWindowInstance.useGrid.selected;
		System.guiSettings.gridSize = Std.parseInt(MainWindowInstance.gridSize.text);
		System.guiSettings.gridType = MainWindowInstance.gridType.value;
		System.guiSettings.gridColor = Std.parseInt(MainWindowInstance.gridColor.text);
		System.guiSettings.gridBorderSize = Std.parseInt(MainWindowInstance.gridBorderSize.text);
		
		(xml == null ? System.frameXml: xml).addChild(Xml.createComment(SuidJson.encode(System.guiSettings)));
	}
	
	public static function getUiSettings (xml:Xml) : GuiDataInfo {
		for(elem in xml)
			if (elem.nodeType == Xml.XmlType.Comment)
				return SuidJson.parse(elem.nodeValue);
		
		return null;
	}
	
	public static function loadUiSettingsFromXml (xml:Xml = null) : Void {
		System.guiSettings = System.getUiSettings(xml == null ? System.frameXml: xml);
		System.refreshGuiSettings();
	}
	
	public static function refreshGuiSettings () : Void {
		switch(System.guiSettings.wgtSrcAct) {
			case 1:
				MainWindowInstance.wgtSrcActLink.selected = true;
			case 2:
				MainWindowInstance.wgtSrcActCopy.selected = true;
			default:
				MainWindowInstance.wgtSrcActNoth.selected = true;
		}
		
		MainWindowInstance.projectPath.text = System.guiSettings.project.escNull();
		MainWindowInstance.parentGuiPath.text = System.guiSettings.parentGuiPath.escNull();
		MainWindowInstance.parentGuiAutoreg.selected = System.guiSettings.parentGuiAutoreg;
		
		MainWindowInstance.wgtSrcDirPath.text = System.guiSettings.srcDir.escNull();
		
		MainWindowInstance.wgtMakeUiInst.selected = System.guiSettings.makeInstance;
		MainWindowInstance.guiInstanceTemplate.value = System.guiSettings.guiInstanceTemplate;
		MainWindowInstance.guiInstanceTemplate.dispatchEvent(new WidgetEvent(WidgetEvent.CHANGE));
		MainWindowInstance.guiInstancePath.text = System.guiSettings.guiInstancePath.escNull();
		MainWindowInstance.guiInstanceFunction.text = System.guiSettings.guiInstanceFunction.escNull();
		
		MainWindowInstance.presetsList.value = System.guiSettings.preset;
		MainWindowInstance.presetsList.dispatchEvent(new WidgetEvent(WidgetEvent.CHANGE));
		MainWindowInstance.embedAssets.selected = System.guiSettings.embedAssets;
		
		MainWindowInstance.framesList.value = System.guiSettings.frameTemplate;
		MainWindowInstance.framesList.dispatchEvent(new WidgetEvent(WidgetEvent.CHANGE));
		
		MainWindowInstance.guiName.text = System.guiSettings.guiName.escNull();
		MainWindowInstance.guiName.dispatchEvent(new WidgetEvent(WidgetEvent.CHANGE));
		
		if (System.guiSettings.guiWidth > 0)
			MainWindowInstance.guiWidth.text = Std.string(System.guiSettings.guiWidth);
		
		if (System.guiSettings.guiHeight > 0)
			MainWindowInstance.guiHeight.text = Std.string(System.guiSettings.guiHeight);
		
		MainWindowInstance.wndBackground.text = System.guiSettings.wndBackground;
		MainWindowInstance.wndFps.text = Std.string(System.guiSettings.wndFps);
		MainWindowInstance.wndVsync.selected = System.guiSettings.wndVsync;
		MainWindowInstance.wndBorderless.selected = System.guiSettings.wndBorderless;
		MainWindowInstance.wndResizable.selected = System.guiSettings.wndResizable;
		MainWindowInstance.wndFullscreen.selected = System.guiSettings.wndFullscreen;
		MainWindowInstance.wndHardware.selected = System.guiSettings.wndHardware;
		MainWindowInstance.wndAllowShaders.selected = System.guiSettings.wndAllowShaders;
		MainWindowInstance.wndRequireShaders.selected = System.guiSettings.wndRequireShaders;
		MainWindowInstance.wndDepthBuffer.selected = System.guiSettings.wndDepthBuffer;
		MainWindowInstance.wndStencilBuffer.selected = System.guiSettings.wndStencilBuffer;
		MainWindowInstance.wndOrientation.value = System.guiSettings.wndOrientation;
		
		MainWindowInstance.useGrid.selected = System.guiSettings.useGrid;
		MainWindowInstance.gridSize.text = Std.string(System.guiSettings.gridSize);
		MainWindowInstance.gridType.value = System.guiSettings.gridType;
		MainWindowInstance.gridColor.text = '0x${System.guiSettings.gridColor.hex()}';
		MainWindowInstance.gridBorderSize.text = Std.string(System.guiSettings.gridBorderSize);
	}
	
	public static function getParentGuiWgtName () : String
		return
			FileSystem.exists(System.guiSettings.parentGuiPath.escNull()) ?
			HxExpr.evaluate(SuidXml.parseXml(File.getContent(Suid.fullPath(System.guiSettings.parentGuiPath))).firstElement().get("name")) :
			"";
	
	//-----------------------------------------------------------------------------------------------
	// tab Designer: widget's movement
	
	public static function onWgtClick (e:MouseEvent) : Void {
		var selWgt:Dynamic = null;
		
		if (System.selWgtData != null)
			if (FileSystem.exists(System.selWgtData.xml.escNull())) {
				var selXml:Xml = SuidXml.parseXml(File.getContent(System.selWgtData.xml)).firstElement();
				
				selWgt = RTXml.buildFn(selXml.toString())();
				
				var dTargetWgt:Dynamic = e.currentTarget;
				var targetWgt:Widget = cast(dTargetWgt, Widget);
				
				if (Std.is(selWgt, Tip)) {
					if (Type.getClass(dTargetWgt) != GuiElements) {
						for (tipAttr in selXml.attributes()) {
							System.wgtUiXmlMap.get(System.selWgt).set('tip:Tip-${tipAttr}', selXml.get(tipAttr));
							System.addPropRow('tip:Tip-${tipAttr}', selXml.get(tipAttr));
							
							System.setWgtProperty(dTargetWgt, 'tip:Tip-${tipAttr}', selXml.get(tipAttr));
						}
						
						StablexUIMod.applyDefaults(targetWgt.tip);
					}
				}
				else if (System.isContainer(Type.getClass(dTargetWgt))) {
					if (Std.is(selWgt, TabPage)) {
						while (!Std.is(dTargetWgt, TabStack) && !Std.is(dTargetWgt, GuiElements))
							dTargetWgt = dTargetWgt.parent;
						
						if (!Std.is(dTargetWgt, TabStack)) {
							Haxity.error("Add widget", "Parent TabStack was not found!");
							return;
						}
					}
					
					targetWgt.addChild(selWgt);
					
					var targetXml:Xml = System.wgtUiXmlMap.get(targetWgt);
					targetXml.addChild(selXml);
					
					System.wgtUiXmlMap.set(selWgt, selXml);
					System.setupEachWidget(selWgt);
					
					if (!Std.is(e.currentTarget, Box) && !Std.is(e.currentTarget, TabStack)) {
						System.setWgtProperty(selWgt, "top", Std.string(Std.int(e.localY)));
						System.setWgtProperty(selWgt, "left", Std.string(Std.int(e.localX)));
						
						cast(selWgt, Widget).dispatchEvent(new MouseEvent(MouseEvent.MOUSE_DOWN));
						cast(selWgt, Widget).dispatchEvent(new MouseEvent(MouseEvent.MOUSE_UP));
					}
				}
				
				targetWgt.refresh();
			}
		
		MainWindowInstance.wlSelectBtn.selected = true;
		
		e.stopPropagation();
	}
	
	public static function onMoveWgtMouseDown (e:MouseEvent) : Void {
		if (MainWindowInstance.wlDeleteBtn.selected)
			System.deleteWidget(e.currentTarget);
		else if (System.wgtUiXmlMap.exists(e.currentTarget)) {
			System.selWgt = e.currentTarget;
			
			System.moveWgt  = e.currentTarget;
			System.moveWgtX = e.stageX;
			System.moveWgtY = e.stageY;
			
			System.showWgtPropList();
		}
		
		e.stopPropagation();
	}
	
	public static function onMoveWgtMouseMove (e:MouseEvent) : Void {
		if (System.moveWgt != null) {
			var mWgt:Widget = cast(System.moveWgt, Widget);
			
			var gridMove:Float->Bool = function (newPos:Float) : Bool {
				if (MainWindowInstance.useGrid.selected)
					return (newPos % Std.parseFloat(MainWindowInstance.gridSize.text)) == 0;
				
				return true;
			}
			
			var nTop:Float = mWgt.top + e.stageY - System.moveWgtY;
			
			if (gridMove(nTop) && nTop >= 0 && (nTop + mWgt.h) <= cast(mWgt.parent, Widget).h) {
				System.setWgtProperty(System.moveWgt, "top", Std.string(nTop));
				System.moveWgtY = e.stageY;
			}
			
			var nLeft:Float = mWgt.left + e.stageX - System.moveWgtX;
			
			if (gridMove(nLeft) && nLeft >= 0 && (nLeft + mWgt.w) <= cast(mWgt.parent, Widget).w) {
				System.setWgtProperty(System.moveWgt, "left", Std.string(nLeft));
				System.moveWgtX = e.stageX;
			}
			
			e.stopPropagation();
		}
	}
	
	public static function onMoveWgtMouseUp (e:MouseEvent) : Void {
		System.moveWgt = null;
		System.moveWgtX = 0;
		System.moveWgtY = 0;
	}
	
	//-----------------------------------------------------------------------------------------------
	// gui builder
	
	public static function isContainer (wgtClass:Class<Dynamic>) : Bool {
		return
			wgtClass == GuiElements ||
			wgtClass == ru.stablex.ui.widgets.Box ||
			wgtClass == ru.stablex.ui.widgets.VBox ||
			wgtClass == ru.stablex.ui.widgets.HBox ||
			wgtClass == ru.stablex.ui.widgets.Widget ||
			wgtClass == ru.stablex.ui.widgets.Scroll ||
			wgtClass == ru.stablex.ui.widgets.TabPage ||
			wgtClass == ru.stablex.ui.widgets.TabStack ||
			wgtClass == ru.stablex.ui.widgets.ViewStack ||
			wgtClass == ru.stablex.ui.widgets.Floating;
	}
	
	public static function iterateWidgets (dWgt:Dynamic, onBefore:Dynamic = null, onBox:Dynamic = null, onChild:Dynamic = null, onWgt:Dynamic = null, onAfter:Dynamic = null) : Void {
		if (onBefore != null)
			onBefore(dWgt);
		
		if (System.isContainer(Type.getClass(dWgt))) {
			if (onBox != null)
				onBox(dWgt);
			
			for (i in 0...cast(dWgt, Widget).numChildren) {
				var chWgt:Dynamic = cast(dWgt, Widget).getChildAt(i);
				
				if (Std.is(chWgt, Widget)) {
					if (onChild != null)
						onChild(dWgt, chWgt, i);
					
					System.iterateWidgets(chWgt, onBefore, onBox, onChild, onWgt, onAfter);
				}
			}
		}
		else if (onWgt != null)
			onWgt(dWgt);
		
		if (onAfter != null)
			onAfter(dWgt);
	}
	
	public static function setupEachWidget (rWgt:Dynamic) : Void {
		System.iterateWidgets(rWgt,
			function (dWgt:Dynamic) {
				#if debug
					trace("");
					trace("setupEachWidget:onBefore");
					trace("   dWgt class: ", Type.getClassName(Type.getClass(dWgt)));
					trace("   dWgt super class: ", Type.getClassName(untyped Type.getClass(dWgt).__super__));
					trace("   dWgt parent class: ", Type.getClassName(Type.getClass(cast(dWgt, Widget).parent)));
					trace("   dWgt exists: ", System.wgtUiXmlMap.exists(dWgt));
				#end
				
				var wgt:Widget = cast(dWgt, Widget);
				
				wgt.addEventListener(MouseEvent.MOUSE_DOWN, function (e:MouseEvent) MainWindowInstance.mainWnd.dispatchEvent(new MouseEvent(MouseEvent.MOUSE_DOWN)));
				
				wgt.addEventListener(MouseEvent.MOUSE_UP, System.onMoveWgtMouseUp);
				wgt.addEventListener(MouseEvent.RIGHT_CLICK, function (e:MouseEvent) MainWindowInstance.wlSelectBtn.selected = true);
				
				if (System.wgtUiXmlMap.exists(dWgt)) {
					wgt.addEventListener(MouseEvent.CLICK, System.onWgtClick);
					
					if (Type.getClass(dWgt) != GuiElements) {
						wgt.addEventListener(MouseEvent.MOUSE_DOWN, System.onMoveWgtMouseDown);
						wgt.addEventListener(MouseEvent.MOUSE_MOVE, System.onMoveWgtMouseMove);
						
						MainWindowInstance.guiWgtsList.options.push(['${wgt.name}:${Type.getClassName(Type.getClass(dWgt))}', wgt.name]);
					}
				}
			},
			function (dWgt:Dynamic) {
				if (System.wgtUiXmlMap.exists(dWgt)) {
					if (MainWindowInstance.useGrid.selected && MainWindowInstance.gridType.value > 0) { // draw grid
						var wgt:Widget = cast(dWgt, Widget);
						var origApplySkin:Void->Void = Reflect.field(dWgt, "applySkin");
						
						Reflect.setField(dWgt, "applySkin", function () : Void {
							origApplySkin();
							
							var color:Int = Std.parseInt(MainWindowInstance.gridColor.text);
							var gridSize:Float = Std.parseFloat(MainWindowInstance.gridSize.text);
							var gridBorderSize:Float = Std.parseFloat(MainWindowInstance.gridBorderSize.text);
							
							if (MainWindowInstance.gridType.value == 1) {
								var x:Float = gridSize;
								
								while (x < wgt.w) {
									var y:Float = gridSize;
									
									while (y < cast(dWgt, Widget).h) {
										wgt.graphics.beginFill(color);
										wgt.graphics.drawRect(x, y, gridBorderSize, gridBorderSize);
										wgt.graphics.endFill();
										
										y += gridSize;
									}
									
									x += gridSize;
								}
							}
							else if (MainWindowInstance.gridType.value == 2) {
								var i:Float = gridSize;
								
								while (i < Math.max(wgt.w, wgt.h)) {
									if (i < wgt.w) { // draw vertical line
										wgt.graphics.lineStyle(1, color, 1);
										wgt.graphics.moveTo(i, 0);
										wgt.graphics.lineTo(i, wgt.h);
									}
									
									if (i < wgt.h) { // draw vertical line
										wgt.graphics.lineStyle(1, color, 1);
										wgt.graphics.moveTo(0, i);
										wgt.graphics.lineTo(wgt.w, i);
									}
									
									i += gridSize;
								}
							}
						});
					}
				}
			},
			function (dParentWgt:Dynamic, dChildWgt:Dynamic, cInd:Int) {
				#if debug
					trace("");
					trace("setupEachWidget:onChild");
					trace("   parent:", Type.getClassName(Type.getClass(dParentWgt)));
					trace("   child:", Type.getClassName(Type.getClass(dChildWgt)));
					trace("   cInd:", cInd);
				#end
				
				if (System.wgtUiXmlMap.get(dChildWgt) == null) {
					var chXml:Xml = System.wgtUiXmlMap.get(dParentWgt).getChildAt(cInd);
					
					if (chXml != null)
						if (StablexUIMod.resolveClass(chXml.nodeName) == Type.getClass(dChildWgt))
							System.wgtUiXmlMap.set(dChildWgt, chXml);
				}
			},
			function (dWgt:Dynamic) {
				cast(dWgt, Widget).addEventListener(MouseEvent.CLICK, function (e:MouseEvent) MainWindowInstance.wlSelectBtn.selected = true);
			},
			function (dWgt:Dynamic) {
				StablexUIMod.applyDefaults(dWgt);
			}
		);
	}
	
	public static function loadUiFromXml (xml:Xml) : Bool {
		if (xml.nodeName == "GuiElements") {
			System.guiElementsWgt = null;
			System.guiElementsXml = System.guiElementsXml.replaceWith(xml);
			
			xml = System.frameXml;
		}
		
		var savedGuiElemsWgt = (System.guiElementsWgt != null ? System.guiElementsWgt.numChildren > 0 : false) ? System.guiElementsWgt : null;
		var savedGuiElemsXml = System.guiElementsXml != null ? System.guiElementsXml.clone() : null;
		
		if (savedGuiElemsWgt != null)
			savedGuiElemsWgt.parent.removeChild(savedGuiElemsWgt);
		
		MainWindowInstance.wgtMainWndContainer.freeChildren(true);
		MainWindowInstance.guiWgtsList.options = [ ["", null] ];
		MainWindowInstance.wgtsPropsLst.freeChildren(true);
		
		System.wgtUiXmlMap = new Map<{}, Xml>();
		
		var wgtDyn:Dynamic = RTXml.buildFn(SuidXml.printXml(xml, "   "))();
		
		if (Type.getClass(wgtDyn) == ru.stablex.ui.widgets.Floating)
			cast(wgtDyn, Floating).show();
		
		System.frameWgt = cast(wgtDyn, Widget);
		System.frameXml = xml;
		
		System.frameWgt.name = System.guiSettings.guiName;
		System.frameXml.set("name", "'" + System.guiSettings.guiName + "'");
		
		if (savedGuiElemsWgt != null && savedGuiElemsXml != null) { // allow to save widgets after frame changed
			System.guiElementsWgt = savedGuiElemsWgt;
			
			var parent:Widget = cast(System.frameWgt.getChild("guiElements").parent, Widget);
			parent.removeChild(parent.getChild("guiElements"));
			parent.addChild(System.guiElementsWgt);
			
			for (elem in System.guiElementsXml.elements())
				System.guiElementsXml.removeChild(elem);
			
			for (elem in savedGuiElemsXml.elements()) {
				savedGuiElemsXml.removeChild(elem);
				System.guiElementsXml.addChild(elem);
			}
			
			System.guiElementsXml = System.frameXml.getByXpath("//GuiElements").replaceWith(System.guiElementsXml);
		}
		else {
			var geDyn:Dynamic = System.frameWgt.getChild("guiElements");
			
			if (geDyn == null) {
				geDyn = new GuiElements();
				System.frameWgt.addChild(geDyn);
			}
			
			System.guiElementsWgt = cast(geDyn, Widget);
			
			var geXml:Xml = System.frameXml.getByXpath("//GuiElements");
			
			if (geXml == null) {
				geXml = Xml.createElement("GuiElements");
				System.frameXml.addChild(geXml);
			}
			
			System.guiElementsXml = geXml;
		}
		
		MainWindowInstance.wgtMainWndContainer.addChild(System.frameWgt);
		
		System.wgtUiXmlMap.set(System.guiElementsWgt, System.guiElementsXml);
		System.setupEachWidget(System.frameWgt);
		
		System.selectWgtFromList(0); // select first widget from list
		
		MainWindowInstance.xmlSource.text = SuidXml.printXml(System.guiElementsXml, "   ");
		
		return true;
	}
	
	//-----------------------------------------------------------------------------------------------
	// gui file
	
	public static function loadUiFromFile (xmlPath:String) : Bool {
		System.uiDirPath = Path.directory(xmlPath);
		System.uiXmlPath = xmlPath;
		
		var guiXml:Xml = SuidXml.parseXml(File.getContent(xmlPath)).firstElement();
		System.loadUiSettingsFromXml(guiXml);
		
		return System.loadUiFromXml(guiXml);
	}
	
	public static function saveUiToFile (xmlPath:String) : Bool {
		if (MainWindowInstance.designerTabs.activeTab().name != "tabXml")
			MainWindowInstance.xmlSource.text = SuidXml.printXml(System.guiElementsXml, "   ");
		
		System.saveUiSettingsToXml();
		
		if (System.loadUiFromXml(SuidXml.parseXml(MainWindowInstance.xmlSource.text).firstElement())) {
			System.uiDirPath = Path.directory(xmlPath);
			System.uiXmlPath = xmlPath;
			
			File.saveContent(System.uiXmlPath, SuidXml.printXml(System.frameXml, "	"));
			
			return true;
		}
		
		return false;
	}
	
	//-----------------------------------------------------------------------------------------------
	// widget
	
	public static function deleteWidget (wgt:Dynamic) : Void {
		if (!Std.is(wgt, Widget))
			return;
		
		if (wgt == System.selWgt) {
			System.selWgt = null;
			System.selPropName = "";
			System.selWgtProp = null;
			System.selWgtProps = null;
			MainWindowInstance.wgtsPropsLst.freeChildren(true);
		}
		
		if (System.isContainer(Type.getClass(wgt)))
			for (i in 0...cast(wgt, Widget).numChildren)
				System.deleteWidget(cast(wgt, Widget).getChildAt(i));
		
		if (System.wgtUiXmlMap.exists(wgt)) {
			System.wgtUiXmlMap.get(wgt).removeSelf();
			System.wgtUiXmlMap.remove(wgt);
		}
		
		System.iterateWidgets(wgt, function (delWgt:Dynamic) {
			if (MainWindowInstance.guiWgtsList.options.length > 1) {
				for (opt in MainWindowInstance.guiWgtsList.options)
					if (opt[1] == cast(delWgt, Widget).name) {
						MainWindowInstance.guiWgtsList.options.remove(opt);
						MainWindowInstance.guiWgtsList.refresh();
						break;
					}
			}
			else
				MainWindowInstance.guiWgtsList.options = [ ["", null] ];
		});
		
		System.selectWgtFromList(0); // select first widget from list
		
		cast(wgt, Widget).parent.removeChild(wgt);
	}
	
	//-----------------------------------------------------------------------------------------------
	// widget's propety
	
	public static function selectWgtFromList (cond:Dynamic) : Void {
		Reflect.setField(MainWindowInstance.guiWgtsList, "_selectedIdx", -1); // workaround for Options (if value was changed, but not selected index)
		
		if (Std.is(cond, Int))
			MainWindowInstance.guiWgtsList.value = MainWindowInstance.guiWgtsList.options[cond][1];
		else
			MainWindowInstance.guiWgtsList.value = Std.string(cond);
		
		if (MainWindowInstance.guiWgtsList.options.length > 1)
			if (!(MainWindowInstance.guiWgtsList.options[0][1] > ""))
				MainWindowInstance.guiWgtsList.options.remove(MainWindowInstance.guiWgtsList.options[0]);
	}
	
	public static function propNameMap (propName:String) : String {
		return switch (propName.toLowerCase()) {
			case "w": "width";
			case "h": "height";
			default: propName;
		}
	}
	
	public static function showWgtPropList () : Void {
		System.selWgtProps = new Map<String, HBox>();
		
		System.selectWgtFromList(cast(System.selWgt, Widget).name);
		
		MainWindowInstance.wgtsPropsLst.freeChildren(true);
		MainWindowInstance.wgtsPropsLst.layout = new Row();
		cast(MainWindowInstance.wgtsPropsLst.layout, Row).rows = new Array<Float>();
		
		var sx:Xml = System.wgtUiXmlMap.get(System.selWgt);
		
		for (att in sx.attributes())
			System.addPropRow(att, sx.get(att));
	}
	
	public static function setWgtProperty (dWgt:Dynamic, property:String, propValue:String) : Void {
		var wgtXml:Xml = System.wgtUiXmlMap.get(dWgt);
		
		if (wgtXml.exists(property)) {
			var ownerInfo:GuiObjPropOwnerInfo = System.setGuiObjProperties(dWgt, [{ name: property, value: propValue }]).pop();
			
			if (propValue > "")
				wgtXml.set(property, Std.is(Reflect.getProperty(ownerInfo.propOwner, ownerInfo.propName), Float) ? propValue.replace(",", ".") : propValue);
			else
				wgtXml.remove(property);
			
			if (System.selWgtProps != null)
				if (System.selWgtProps.exists(property))
					cast(cast(System.selWgtProps.get(property), HBox).getChild("propValue"), Text).text = Std.string(wgtXml.get(property));
			
			if (property != "left" && property != "top")
				StablexUIMod.applyDefaults(dWgt);
		}
	}
	
	public static function addPropRow (prop:String, value:String) : Void {
		var row:HBox = UIBuilder.buildFn("XmlGui/WgtPropRow.xml")();
		
		cast(row.getChild("propLabel"), Text).text = System.propNameMap(prop);
		cast(row.getChild("propValue"), Text).text = value.toLowerCase() == "null" ? "" : value;
		
		row.addEventListener(MouseEvent.CLICK, function (e:MouseEvent) {
			if (System.selWgtProp != null) {
				cast(System.selWgtProp.skin, Paint).border = 0;
				try { System.selWgtProp.refresh(); } catch (ex:Dynamic) { } // skin prop selection after wgt_moved "Uncaught exception - Invalid field access : get_width"
			}
			
			System.selWgtProp = cast(e.currentTarget, HBox);
			System.selPropName = prop;
			
			cast(System.selWgtProp.skin, Paint).border = 1;
			System.selWgtProp.refresh();
		});
		
		cast(MainWindowInstance.wgtsPropsLst.layout, Row).rows.push(20);
		MainWindowInstance.wgtsPropsLst.addChild(row);
		
		System.selWgtProps.set(prop, row);
	}
	
	//-----------------------------------------------------------------------------------------------
	// gui objects's propety
	
	public static function getGuiObjProperty (propOwner:Dynamic, propName:String) : Dynamic {
		return Std.is(propOwner, DynamicList) ?
			Reflect.callMethod(propOwner, Reflect.field(propOwner, "get"), [propName]) :
			Reflect.getProperty(propOwner, propName);
	}
	
	public static function getGuiObjDefaultPropValue (obj:Dynamic, propName:String, objCls:Class<Dynamic> = null) : Dynamic {
		if (objCls == null)
			objCls = Type.getClass(obj);
		
		if (objCls != null) {
			var defOwner:GuiObjPropOwnerInfo = System.getPropertyOwner(Type.createInstance(objCls, []), propName);
			
			if (defOwner.propOwner != null) {
				var prop:Dynamic = System.getGuiObjProperty(defOwner.propOwner, defOwner.propName);
				return Std.is(prop, String) ? "'" + prop + "'" : prop;
			}
		}
		
		return null;
	}
	
	public static function getPropertyOwner (wgt:Dynamic, property:String) : GuiObjPropOwnerInfo {
		var propLst:Array<String> = property.split("-");
		
		var propOwner:Dynamic = wgt;
		var propName:String = property;
		
		for (i in 0...propLst.length) {
			var ppInfo:Array<String> = propLst[i].split(":");
			propName = ppInfo[0];
			
			if (i < (propLst.length - 1)) {
				if (System.getGuiObjProperty(propOwner, propName) == null) {
					var propCls:Class<Dynamic> = null;
					
					if (ppInfo.length > 1)
						propCls = StablexUIMod.resolveClass(ppInfo[1]);
					else
						propCls = System.rttiGetPropertyType(propOwner, propName);
					
					Reflect.setProperty(propOwner, propName, Type.createInstance(propCls, []));
				}
				
				propOwner = System.getGuiObjProperty(propOwner, propName);
			}
		}
		
		return { propOwner: propOwner, propName: propName };
	}
	
	public static function setGuiObjProperties (obj:Dynamic, properies:Array<GuiObjPropInfo>) : Array<GuiObjPropOwnerInfo> {
		var owners:Array<GuiObjPropOwnerInfo> = new Array<GuiObjPropOwnerInfo>();
		
		for (propInfo in properies) {
			var ownerInfo:GuiObjPropOwnerInfo = System.getPropertyOwner(obj, propInfo.name);
			var prop:Dynamic = Reflect.getProperty(ownerInfo.propOwner, ownerInfo.propName);
			
			var dynValue:Dynamic;
			
			if (Std.is(propInfo.value, String)) {
				if (Std.is(prop, Float))
					propInfo.value = propInfo.value.replace(",", "."); // workaround: error with ',' when trying to parse Float
				
				propInfo.value = propInfo.value.replace("%SUIDCWD", '"${Suid.getCwd()}"').replace("%CWD", '"${Suid.getCwd()}"');
				
				HxExpr.setVar("__ui__this", obj);
				
				dynValue = HxExpr.evaluate(propInfo.value);
			}
			else
				dynValue = propInfo.value;
			
			try {
				Reflect.setProperty(ownerInfo.propOwner, ownerInfo.propName, dynValue);
			}
			catch (ex:Dynamic) {
				#if debug
					trace("");
					trace("      owner class: ", Type.getClassName(Type.getClass(ownerInfo.propOwner)));
					trace("      prop name: ", ownerInfo.propName);
					trace("");
					
					trace("      prop type: ", Type.typeof(Reflect.getProperty(ownerInfo.propOwner, ownerInfo.propName)));
					trace("      prop cls name: ", Type.getClassName(Type.getClass(Reflect.getProperty(ownerInfo.propOwner, ownerInfo.propName))));
					trace("      prop value: ", Reflect.getProperty(ownerInfo.propOwner, ownerInfo.propName));
					trace("");
					
					trace("      new type: ", Type.typeof(dynValue));
					trace("      new cls name: ", Type.getClassName(Type.getClass(dynValue)));
					trace("      new value: ", dynValue);
					trace("");
				#end
				
				throw ex;
			}
			
			owners.push(ownerInfo);
		}
		
		return owners;
	}
	
	//-----------------------------------------------------------------------------------------------
	// rtti functions
	
	public static function rttiGetFieldType (objCls:Class<Dynamic>, fieldName:String) : Class<Dynamic> {
		var propCls:Class<Dynamic> = null;
		
		if (haxe.rtti.Rtti.hasRtti(objCls)) {
			var rtti = haxe.rtti.Rtti.getRtti(objCls);
			
			for (sf in rtti.fields)
				if (sf.name == fieldName) {
					propCls = StablexUIMod.resolveClass(haxe.rtti.CType.CTypeTools.toString(sf.type));
					break;
				}
			
			if (propCls == null)
				if (rtti.superClass != null)
					propCls = System.rttiGetFieldType(StablexUIMod.resolveClass(rtti.superClass.path), fieldName);
		}
		
		return propCls;
	}
	
	public static function rttiGetPropertyType (objCls:Class<Dynamic>, properyName:String) : Class<Dynamic> {
		var fldCls:Class<Dynamic> = objCls;
		
		for (fld in properyName.split("-")) {
			var fldData:Array<String> = fld.split(":");
			fldCls = fldData.length == 1 ? System.rttiGetFieldType(fldCls, fldData[0]) : StablexUIMod.resolveClass(fldData[1]);
		}
		
		return fldCls;
	}
}
