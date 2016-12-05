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
	
	public static function setInstanceInitHxFlag (oldInstancePath:String) : Void {
		var projXml:Xml = System.parseXml(File.getContent(System.guiSettings.project)).firstElement();
		
		var getInstance:String->String = function (instPath:String) : String
			return
				Path.withoutExtension(FileSystem.fullPath(instPath)
					.replace(Path.addTrailingSlash(Path.join([
						Path.directory(FileSystem.fullPath(System.guiSettings.project)),
						projXml.getByXpath("//project/source").get("path")
					])), ""))
				.replace("/", ".")
				.replace("\\", ".") + ".geInit()";
		
		if (oldInstancePath > "")
			projXml.getByXpath('//project/haxeflag[@name="--macro" and @value="${getInstance(oldInstancePath)}"]').removeSelf();
		
		if (System.guiSettings.makeInstance)
			if (System.guiSettings.guiInstancePath > "") {
				var instXml:Xml = Xml.createElement("haxeflag");
				instXml.set("name", "--macro");
				instXml.set("value", getInstance(System.guiSettings.guiInstancePath));
				
				projXml.addChild(instXml);
			}
		
		File.saveContent(FileSystem.fullPath(System.guiSettings.project), System.printXml(projXml, "	"));
	}
	
	public static function makeInstance () : Bool {
		if (!FileSystem.exists(System.guiSettings.project.escNull()) || !(System.guiSettings.guiInstancePath > "") || !(System.guiSettings.guiUuid > ""))
			return false;
		
		var cli:Int = 0;
		var gii:Int = -1;
		var fli:Int = -1;
		var bii:Int = -1;
		var rli:Int = -1;
		var ili:Int = -1;
		
		var gUuidStr:String = 'guiUuid=${System.guiSettings.guiUuid}';
		
		var gXmlName:String = Path.withoutDirectory(System.uiXmlPath);
		var gXmlRelPath:String = FileSystemHelper.getRelativePath(Path.directory(System.guiSettings.project), System.uiXmlPath);
		var rootWgtName:String = System.guiSettings.rootName > "" ? System.guiSettings.rootName : System.guiSettings.guiName;
		var instanceName:String = Path.withoutExtension(Path.withoutDirectory(System.guiSettings.guiInstancePath));
		
		var instPath:String =
			FileSystem.exists(System.guiSettings.guiInstancePath) ?
			System.guiSettings.guiInstancePath :
			FileSystem.fullPath(Path.join(["instances", System.guiSettings.guiInstanceTemplate]));
		
		var instLines:Array<String> = File.getContent(instPath)
			.split("\n")
				.filter(function (hxLine:String) : Bool
					return
						hxLine.indexOf(gUuidStr) < 0 &&
						hxLine.indexOf("UIBuilder.init") < 0 &&
						hxLine.indexOf("UIBuilder.regSkins") < 0 &&
						hxLine.indexOf("UIBuilder.buildClass") < 0 &&
						hxLine.indexOf("UIBuilder.customStringReplace") < 0
				)
				.map (function (hxLine:String) : String
					return hxLine
						.replace("%InstanceName%", instanceName)
						.replace("%InstancePackage%", Xml.parse(File.getContent(System.guiSettings.project)).getByXpath("//project/app").get("main").split(".").slice(0, -1).join("."))
				)
				.map (function (hxLine:String) : String {
					if (hxLine.indexOf("// create source of GuiElements class") >= 0)
						gii = cli + 1;
					else if (hxLine.indexOf("// fields of instances") >= 0)
						fli = cli + 1;
					else if (hxLine.indexOf("// UIBuilder initialization") >= 0)
						bii = cli + 1;
					else if (hxLine.indexOf("// skins registration") >= 0)
						rli = cli + 1;
					else if (hxLine.indexOf("// initialization of instances") >= 0)
						ili = cli + 1;
					
					cli++;
					
					return hxLine;
				});
		
		var relPath:String = FileSystemHelper.getRelativePath(Path.directory(System.guiSettings.project), Sys.getCwd());
		
		instLines.insert(gii, '		ru.stablex.ui.UIBuilder.buildClass("${haxe.io.Path.join([relPath, "GuiElements.xml"])}", "GuiElements");');
		
		fli++;
		bii++;
		rli++;
		ili++;
		
		instLines.insert(bii, '		ru.stablex.ui.UIBuilder.customStringReplace = function (strValue:String) : String return StringTools.replace(StringTools.replace(strValue, "SUIDCWD", "${Sys.getCwd()}"), "CWD", Sys.getCwd());');
		
		var preset:PresetInfo = System.wgtPresetsMap.get(System.guiSettings.preset);
		var presetPath:String = '"${FileSystemHelper.getRelativePath(Path.directory(System.guiSettings.project), Path.join([preset.dir, preset.xml]))}"';
		
		instLines.insert(bii + 1, '		ru.stablex.ui.UIBuilder.init($presetPath, ${instLines[bii - 1].indexOf("RTXml") >= 0});');
		
		rli += 2;
		ili += 2;
		
		for (suite in System.wgtSuitsMap.keys()) {
			instLines.insert(rli, '		ru.stablex.ui.UIBuilder.regSkins("${Path.join([relPath, "suits", suite, System.wgtSuitsMap[suite].xml])}");');
			
			ili++;
		}
		
		while (ili < instLines.length) {
			if (instLines[ili].indexOf("}") >= 0 ||
				(System.guiSettings.guiName == rootWgtName) ||
				(System.guiSettings.guiName != rootWgtName && instLines.indexOf('$instanceName.$rootWgtName =') >= 0))
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
					if (wgtName == rootWgtName) {
						instLines.insert(ili, '		$instanceName.$wgtName = ru.stablex.ui.UIBuilder.buildFn("$gXmlRelPath")(); // $gUuidStr ($gXmlName)');
						ili++;
						instLines.insert(ili, Std.is(wgt, Floating) ? '		$instanceName.$wgtName.show(); // $gUuidStr ($gXmlName)' : '		openfl.Lib.current.stage.addChild($instanceName.$wgtName); // $gUuidStr ($gXmlName)');
					}
					else
						instLines.insert(ili, '		$instanceName.$wgtName = cast($instanceName.$rootWgtName.getChild("$wgtName"), $wgtClassName); // $gUuidStr ($gXmlName)');
				}
				else
					instLines.insert(ili + wgtInd, '		$instanceName.$wgtName = cast($instanceName.${System.guiSettings.guiName}.getChild("$wgtName"), $wgtClassName); // $gUuidStr ($gXmlName)');
				
				wgtInd++;
			}
		});
		
		File.saveContent(System.guiSettings.guiInstancePath, instLines.join("\n"));
		
		return true;
	}
	
	public static function clearWgtSources () : Void {
		//...
		//...
		//...
	}
	
	public static function registerWgtSources (copy:Bool, destDir:String = null) : Bool {
		var result:Bool = true;
		
		if (!copy) {
			if (FileSystem.exists(System.guiSettings.project.escNull())) {
				var projXml:Xml = System.parseXml(File.getContent(System.guiSettings.project)).firstElement();
				
				for (src in wgtSources) {
					var srcPath:String = FileSystemHelper.getRelativePath(Path.directory(System.guiSettings.project), src);
					
					if (projXml.getByXpath('//project/source[@path="$srcPath"]') == null) {
						var srcXml:Xml = Xml.createElement("source");
						srcXml.set("path", srcPath);
						
						projXml.addChild(srcXml);
					}
				}
				
				File.saveContent(FileSystem.fullPath(System.guiSettings.project), System.printXml(projXml, "	"));
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
		if (!FileSystem.exists(System.guiSettings.project.escNull()) || !(System.guiSettings.guiUuid > ""))
			return false;
		
		var projXml:Xml = System.parseXml(File.getContent(System.guiSettings.project)).firstElement();
		
		for (xa in projXml.findByXpath('//project/assets[@guiUuid="${System.guiSettings.guiUuid}"]'))
			xa.removeSelf();
		
		var assets:Array<String> = new Array<String>();
		
		for (i in [System.wgtSuitsMap.iterator(), System.wgtPresetsMap.iterator()])
			for (a in i.array().filter(function (e:Dynamic) : Bool return e.assets > "")) {
				var xa:Xml = Xml.createElement("assets");
				xa.set("path", FileSystemHelper.getRelativePath(Path.directory(System.guiSettings.project), Path.join([a.dir, a.assets])));
				xa.set("rename", Path.join([a.dir, a.assets]).replace(Path.addTrailingSlash(Sys.getCwd()), ""));
				xa.set("guiUuid", System.guiSettings.guiUuid);
				projXml.addChild(xa);
			}
		
		File.saveContent(FileSystem.fullPath(System.guiSettings.project), System.printXml(projXml, "	"));
		
		return true;
	}
}
