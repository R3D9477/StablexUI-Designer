package rn.stablex.designer;

import sys.io.File;
import haxe.io.Path;
import sys.FileSystem;

import ru.stablex.ui.widgets.*;

import rn.typext.hlp.FileSystemHelper;

using Lambda;
using StringTools;
using rn.typext.ext.XmlExtender;
using rn.typext.ext.IterExtender;
using rn.typext.ext.StringExtender;

class SourceControl {
	public static var wgtSources:Array<String> = new Array<String>();
	public static var extClasses:Array<String> = new Array<String>();
	
	//-----------------------------------------------------------------------------------------------
	// instance generation
	
	public static function makeInstance () : Bool {
		if (
				!FileSystem.exists(System.guiSettings.project.escNull()) ||
				StringExtender.isNullOrEmpty(System.guiSettings.guiInstancePath) ||
				StringExtender.isNullOrEmpty(System.guiSettings.guiUuid)
			)
			return false;
		
		var gUuidStr:String = 'guiUuid=${System.guiSettings.guiUuid}';
		
		var gXmlName:String = Path.withoutDirectory(System.uiXmlPath);
		var gXmlRelPath:String = FileSystemHelper.getRelativePath(Path.directory(System.guiSettings.project), System.uiXmlPath);
		var parentWgtName:String = System.getParentGuiWgtName();
		var instanceName:String = Path.withoutExtension(Path.withoutDirectory(System.guiSettings.guiInstancePath));
		var instanceFunctionName:String = System.guiSettings.guiInstanceFunction.split(".").pop().split("(").shift().trim();
		
		var instPath:String =
			FileSystem.exists(System.guiSettings.guiInstancePath) ?
			System.guiSettings.guiInstancePath :
			Suid.fullPath(Path.join(["instances", System.guiSettings.guiInstanceTemplate]));
		
		var pack:String = SourceControl.getProjectPackage();
		var packDot:String = !StringExtender.isNullOrEmpty(pack) ? '$pack.' : "";
		
		var relPath:String = FileSystemHelper.getRelativePath(Path.directory(System.guiSettings.project), Suid.getCwd());
		var preset:PresetInfo = System.wgtPresetsMap.get(System.guiSettings.preset);
		var presetPath:String = FileSystemHelper.getRelativePath(Path.directory(System.guiSettings.project), Path.join([preset.dir, preset.xml]));
		
		var cli:Int = 0;
		var sii:Int = -1;
		var cri:Int = -1;
		var eri:Int = -1;
		var gii:Int = -1;
		var fli:Int = -1;
		var rli:Int = -1;
		var ili:Int = -1;
		
		var instLines:Array<String> = File.getContent(instPath)
			.split("\n")
				.filter(function (hxLine:String) : Bool
					return
						hxLine.indexOf(gUuidStr) < 0 &&
						hxLine.indexOf("UIBuilder.regSkins") < 0
				)
				.map (function (hxLine:String) : String
					return hxLine
						.replace("%InstanceName%", instanceName)
						.replace("%InstanceFunctionName%", instanceFunctionName)
						.replace("%InstancePackage%", pack)
						.replace("%InstancePackageDot%", packDot)
						.replace("%DefaultsPath%", presetPath)
						.replace("%SuidCwd%", relPath)
				)
				.map (function (hxLine:String) : String {
					if (hxLine.indexOf("// switchers of guiSettings") >= 0)
						sii = cli + 1;
					else if (hxLine.indexOf("// reg classes") >= 0)
						cri = cli + 1;
					else if (hxLine.indexOf("// reg events") >= 0)
						eri = cli + 1;
					else if (hxLine.indexOf("// build sources from xml") >= 0)
						gii = cli + 1;
					else if (hxLine.indexOf("// fields of instances") >= 0)
						fli = cli + 1;
					else if (hxLine.indexOf("// skins registration") >= 0)
						rli = cli + 1;
					else if (hxLine.indexOf("// initialization of instances") >= 0)
						ili = cli + 1;
					
					cli++;
					
					return hxLine;
				});
		
		instLines.insert(sii, '			case "${System.guiSettings.guiName}": ${SuidJson.encode(System.guiSettings)}; // $gUuidStr ($gXmlName)');
		
		cri++;
		eri++;
		gii++;
		fli++;
		rli++;
		ili++;
		
		for (rc in SourceControl.extClasses)
			for (i in 0...instLines.length) {
				var cl:String = instLines[cri + i].trim();
				
				if (cl.length == 0 || cl == "}") {
					cl = '		ru.stablex.ui.UIBuilder.regClass("$rc");';
					instLines.insert(cri + i, cl);
					
					eri++;
					gii++;
					fli++;
					rli++;
					ili++;
				}
				
				if (cl.indexOf('UIBuilder.regClass("$rc")') >= 0)
					break;
			}
		
		if (!StringExtender.isNullOrEmpty(parentWgtName)) {
			instLines.insert(gii, '		ru.stablex.ui.UIBuilder.buildClass("${FileSystemHelper.getRelativePath(Path.directory(System.guiSettings.project), System.uiXmlPath)}", "${SourceControl.fileNameToClassName(System.uiXmlPath)}"); // $gUuidStr ($gXmlName)');
			
			fli++;
			rli++;
			ili++;
		}
		
		for (suite in System.wgtSuitsMap.keys()) {
			instLines.insert(rli, '		ru.stablex.ui.UIBuilder.regSkins("${Path.join([relPath, "suits", suite, System.wgtSuitsMap[suite].xml])}");');
			
			ili++;
		}
		
		while (ili < instLines.length) {
			if (
					instLines[ili].indexOf("}") >= 0 ||
					StringExtender.isNullOrEmpty(parentWgtName) ||
					(!StringExtender.isNullOrEmpty(parentWgtName) && instLines[ili].indexOf('$instanceName.$parentWgtName =') >= 0)
				)
				break;
			
			ili++;
		}
		
		ili++;
		
		var wgtInd:Int = 1;
		System.iterateWidgets(System.frameWgt, function (wgt:Dynamic) : Void {
			if (System.wgtUiXmlMap.exists(wgt) ? System.wgtUiXmlMap.get(wgt).exists("name") : cast(wgt, Widget).name == System.guiSettings.guiName) {
				var wgtName:String = cast(wgt, Widget).name;
				var wgtClassName:String = Type.getClassName(Type.getClass(wgt));
				
				instLines.insert(fli, '	public static var $wgtName:$wgtClassName; // $gUuidStr ($gXmlName)');
				
				if (wgtName == System.guiSettings.guiName) {
					if (StringExtender.isNullOrEmpty(parentWgtName))
						instLines.insert(ili, '		$instanceName.$wgtName = ru.stablex.ui.UIBuilder.buildFn("$gXmlRelPath")(); // $gUuidStr ($gXmlName)');
					else
						instLines.insert(++ili, '		$instanceName.$wgtName = cast($instanceName.$parentWgtName.getChild("$wgtName"), $wgtClassName); // $gUuidStr ($gXmlName)');
				}
				else
					instLines.insert(ili + wgtInd, '		$instanceName.$wgtName = cast($instanceName.${System.guiSettings.guiName}.getChild("$wgtName"), $wgtClassName); // $gUuidStr ($gXmlName)');
				
				wgtInd++;
			}
		});
		
		File.saveContent(System.guiSettings.guiInstancePath, instLines.join("\n"));
		
		return true;
	}
	
	public static function generateInstanceFunction (instancePath:String) : String {
		var funcName:String = "geInit()";
		
		if (FileSystem.exists(System.guiSettings.project.escNull())) {
			var xi:Xml = SuidXml.parseXml(File.getContent(Suid.fullPath(System.guiSettings.project))).firstElement().getByXpath('//project/haxeflag[@suid="instance"]');
			
			if (xi != null)
				funcName = xi.get("value").split(".").pop();
		}
		
		return SourceControl.getProjectPackage(true) + Path.withoutExtension(Path.withoutDirectory(instancePath)) + "." + funcName;
	}
	
	public static function setInstanceInitHxFlag () : Bool {
		if (
				StringExtender.isNullOrEmpty(System.guiSettings.project) ||
				StringExtender.isNullOrEmpty(System.guiSettings.guiInstanceTemplate) ||
				StringExtender.isNullOrEmpty(System.guiSettings.guiInstancePath) ||
				StringExtender.isNullOrEmpty(System.guiSettings.guiInstanceFunction)
			)
			return false;
		
		var projXml:Xml = SuidXml.parseXml(File.getContent(System.guiSettings.project)).firstElement();
		
		var oldInstFunc:Xml = projXml.getByXpath('//project/haxeflag[@suid="instance"]');
		
		if (oldInstFunc != null)
			oldInstFunc.removeSelf();
		
		var instXml:Xml = Xml.createElement("haxeflag");
		instXml.set("name", "--macro");
		instXml.set("value", System.guiSettings.guiInstanceFunction);
		instXml.set("suid", "instance");
		instXml.set("guiUuid", System.guiSettings.guiUuid);
		
		projXml.addChild(instXml);
		
		File.saveContent(Suid.fullPath(System.guiSettings.project), SuidXml.printXml(projXml, "	"));
		
		return true;
	}
	
	//-----------------------------------------------------------------------------------------------
	// openfl/lime project integration
	
	public static function getProjectPackage (withDot:Bool = false) : String {
		var pack:String = FileSystem.exists(System.guiSettings.project.escNull()) ?
			Xml.parse(File.getContent(System.guiSettings.project)).getByXpath("//project/app").get("main").split(".").slice(0, -1).join(".") :
			"";
		
		if (withDot && !StringExtender.isNullOrEmpty(pack))
			pack += ".";
		
		return pack;
	}
	
	public static function checkStablexUILib () : Bool {
		if (!FileSystem.exists(System.guiSettings.project.escNull()))
			return false;
		
		var projXml:Xml = SuidXml.parseXml(File.getContent(System.guiSettings.project)).firstElement();
		
		if (projXml.getByXpath("//project/haxelib[@name='stablexui']") == null) {
			var hxnode:Xml = Xml.createElement("haxelib");
			hxnode.set("name", "stablexui");
			projXml.addChild(hxnode);
			
			File.saveContent(Suid.fullPath(System.guiSettings.project), SuidXml.printXml(projXml, "	"));
		}
		
		return true;
	}
	
	public static function clearWgtSources () : Void {
		if (FileSystem.exists(System.guiSettings.project.escNull())) {
			var projXml:Xml = SuidXml.parseXml(File.getContent(System.guiSettings.project)).firstElement();
			
			//for (clrNode in projXml.findByXpath('//project/source[@guiUuid="${System.guiSettings.guiUuid}"]'))
			//	clrNode.removeSelf();
			
			var clrNode:Xml;
			while ((clrNode = projXml.getByXpath('//project/source[@guiUuid="${System.guiSettings.guiUuid}"]')) != null)
				clrNode.removeSelf();
			
			File.saveContent(Suid.fullPath(System.guiSettings.project), SuidXml.printXml(projXml, "	"));
		}
	}
	
	public static function registerWgtSources (copy:Bool, destDir:String = null) : Bool {
		var result:Bool = true;
		
		if (!copy) {
			if (FileSystem.exists(System.guiSettings.project.escNull())) {
				var projXml:Xml = SuidXml.parseXml(File.getContent(Suid.fullPath(System.guiSettings.project))).firstElement();
				
				for (src in wgtSources) {
					var srcPath:String = FileSystemHelper.getRelativePath(Path.directory(System.guiSettings.project), src);
					
					if (projXml.getByXpath('//project/source[@path="$srcPath"]') == null) {
						var srcXml:Xml = Xml.createElement("source");
						srcXml.set("path", srcPath);
						
						projXml.addChild(srcXml);
					}
				}
				
				File.saveContent(Suid.fullPath(System.guiSettings.project), SuidXml.printXml(projXml, "	"));
			}
			else
				result = false;
		}
		else if (copy && FileSystem.exists(destDir.escNull())) {
			for (src in wgtSources)
				FileSystemHelper.copy(Path.addTrailingSlash(src), Path.addTrailingSlash(destDir));
		}
		else
			result = false;
		
		return result;
	}
	
	public static function embedAssets () : Bool {
		if (!FileSystem.exists(System.guiSettings.project.escNull()) || StringExtender.isNullOrEmpty(System.guiSettings.guiUuid))
			return false;
		
		var projXml:Xml = SuidXml.parseXml(File.getContent(System.guiSettings.project)).firstElement();
		
		//for (clrNode in projXml.findByXpath('//project/assets[@guiUuid="${System.guiSettings.guiUuid}"]'))
		//	clrNode.removeSelf();
		
		var clrNode:Xml;
		while ((clrNode = projXml.getByXpath('//project/assets[@guiUuid="${System.guiSettings.guiUuid}"]')) != null)
			clrNode.removeSelf();
		
		for (map in [System.wgtSuitsMap.iterator(), System.wgtPresetsMap.iterator()])
			for (inf in map.array().filter(function (e:Dynamic) : Bool return e.assets != null))
				for (asset in inf.assets) {
					var xa:Xml = Xml.createElement("assets");
					xa.set("path", FileSystemHelper.getRelativePath(Path.directory(System.guiSettings.project), Path.join([inf.dir, asset])));
					xa.set("rename", Path.join([inf.dir, asset]).replace(Path.addTrailingSlash(Suid.getCwd()), ""));
					xa.set("guiUuid", System.guiSettings.guiUuid);
					projXml.addChild(xa);
				}
		
		File.saveContent(Suid.fullPath(System.guiSettings.project), SuidXml.printXml(projXml, "	"));
		
		return true;
	}
	
	public static function setWindow () : Bool {
		if (
				!FileSystem.exists(System.guiSettings.project.escNull()) ||
				StringExtender.isNullOrEmpty(System.guiSettings.guiUuid)
			)
			return false;
		
		var projXml:Xml = SuidXml.parseXml(File.getContent(System.guiSettings.project)).firstElement();
		
		//for (clrNode in projXml.findByXpath('//project/window[@guiUuid="${System.guiSettings.guiUuid}"]'))
		//	clrNode.removeSelf();
		
		var clrNode:Xml;
		while ((clrNode = projXml.getByXpath('//project/window[@guiUuid="${System.guiSettings.guiUuid}"]')) != null)
			clrNode.removeSelf();
		
		var setWndInfo:Xml->Void = function (x:Xml) : Void {
			x.set("width", Std.string(System.guiSettings.guiWidth));
			x.set("height", Std.string(System.guiSettings.guiHeight));
			
			x.set("background", System.guiSettings.wndBackground);
			x.set("fps", Std.string(System.guiSettings.wndFps));
			x.set("vsync", Std.string(System.guiSettings.wndVsync));
			x.set("borderless", Std.string(System.guiSettings.wndBorderless));
			x.set("resizable", Std.string(System.guiSettings.wndResizable));
			x.set("fullscreen", Std.string(System.guiSettings.wndFullscreen));
			x.set("hardware", Std.string(System.guiSettings.wndHardware));
			x.set("allow-shaders", Std.string(System.guiSettings.wndAllowShaders));
			x.set("require-shaders", Std.string(System.guiSettings.wndRequireShaders));
			x.set("depth-buffer", Std.string(System.guiSettings.wndDepthBuffer));
			x.set("stencil-buffer", Std.string(System.guiSettings.wndStencilBuffer));
			
			x.set("orientation", System.guiSettings.wndOrientation);
			
			x.set("guiUuid", System.guiSettings.guiUuid);
		}
		
		var exists:Bool = false;
		
		for (x in projXml.iterator())
			if (x.nodeName == "window") {
				var valid:Bool = true;
				
				if (x.exists("if"))
					valid = x.get("if").indexOf("flash") < 0 && x.get("if").indexOf("html5") < 0;
				
				x.remove("background");
				x.remove("fps");
				x.remove("vsync");
				x.remove("borderless");
				x.remove("resizable");
				x.remove("fullscreen");
				x.remove("hardware");
				x.remove("allow-shaders");
				x.remove("require-shaders");
				x.remove("depth-buffer");
				x.remove("stencil-buffer");
				x.remove("orientation");
				
				if (valid && (x.exists("width") || x.exists("height"))) {
					setWndInfo(x);
					exists = true;
				}
			}
		
		if (!exists) {
			var sx:Xml = Xml.createElement("window");
			
			sx.set("unless", "mobile");
			setWndInfo(sx);
			
			projXml.addChild(sx);
		}
		
		File.saveContent(Suid.fullPath(System.guiSettings.project), SuidXml.printXml(projXml, "	"));
		
		return true;
	}
	
	//-----------------------------------------------------------------------------------------------
	// xml
	
	public static function registerParentXml () : Bool {
		if (!FileSystem.exists(System.guiSettings.parentGuiPath.escNull()))
			return false;
		
		var parentXml:Xml = SuidXml.parseXml(File.getContent(Suid.fullPath(System.guiSettings.parentGuiPath))).firstElement();
		var chXmlTag:String = SourceControl.fileNameToClassName(System.uiXmlPath);
		var guiName:String = "'" + System.guiSettings.guiName + "'";
		
		var chXml:Xml = parentXml.getByXpath('//$chXmlTag[@name="$guiName"]');
		
		if (chXml == null) {
			chXml = Xml.createElement(chXmlTag);
			chXml.set("name", guiName);
			
			parentXml.addChild(chXml);
			
			File.saveContent(Suid.fullPath(System.guiSettings.parentGuiPath), SuidXml.printXml(parentXml, "	"));
		}
		
		return true;
	}
	
	public static function fileNameToClassName (filename:String) : String {
		filename = Path.withoutExtension(Path.withoutDirectory(filename));
		
		for (symbol in ["-", "_", " ", "(", ")"])
			filename = filename.split(symbol).map(function (s:String) return s.toTitleCase()).join("");
		
		return filename;
	}
}
