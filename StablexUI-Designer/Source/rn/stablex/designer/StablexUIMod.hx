package rn.stablex.designer;

import hscript.Interp;

import ru.stablex.ui.*;
import ru.stablex.ui.widgets.*;

using Lambda;
using StringTools;
using rn.typext.ext.XmlExtender;
using rn.typext.ext.IterExtender;

class StablexUIMod {
	public static var namespaces:Array<String> = [
		"",
		"ru.stablex.",
		"ru.stablex.ui.events.",
		"ru.stablex.ui.layouts.",
		"ru.stablex.ui.misc.",
		"ru.stablex.ui.skins.",
		"ru.stablex.ui.transitions.",
		"ru.stablex.ui.widgets.",
		"openfl.display.",
		"openfl.display3D.",
		"openfl.display3D.textures.",
		"openfl.events.",
		"openfl.filters.",
		"openfl.geom.",
		"openfl.text.",
		"openfl.ui."
	];
	
	public static var rtDefaults:Xml;
	
	public static function remapNamespace (className:String) : String
		return className.replace("flash.", "openfl.");
	
	public static function resolveClass (className:String) : Class<Dynamic> {
		className = StablexUIMod.remapNamespace(className);
		
		var resCls:Class<Dynamic> = null;
		
		for (nmspc in StablexUIMod.namespaces)
			if ((resCls = Type.resolveClass(nmspc + className)) != null)
				break;
		
		return resCls;
	}
	
	public static function applyDefaults (dWgt:Dynamic) : Void { // set defaults for widgets at runtime
		var wgt:Widget = cast(dWgt, Widget);
		
		if (!(wgt.defaults > ""))
			wgt.defaults = "Default";
		
		for (defName in wgt.defaults.split(",")) {
			var defsXml:Xml = StablexUIMod.rtDefaults.getByXpath('//Defaults/${Type.getClassName(Type.getClass(dWgt)).split(".").pop()}/$defName');
			
			if (defsXml != null) {
				var wgtXml:Xml = System.wgtUiXmlMap.get(dWgt);
				
				System.setGuiObjProperties(
					dWgt,
					defsXml.attributes()
						.array()
						.filter(function (attr:String) : Bool {
							if (wgtXml != null) {
								if (attr == "w" || attr.indexOf("width") > -1)
									return !(wgtXml.exists("w") || wgtXml.exists("width") || wgtXml.exists("widthPt"));
								else if (attr == "h" || attr.indexOf("height") > -1)
									return !(wgtXml.exists("h") || wgtXml.exists("height") || wgtXml.exists("heightPt"));
								
								return !wgtXml.exists(attr);
							}
							
							return true;
						})
						.map(function (attr:String) : Dynamic return { name: attr, value: defsXml.get(attr) })
				);
				
				if (Std.is(dWgt, Options)) {
					Reflect.callMethod(dWgt, Reflect.field(dWgt, "_buildList"), []);
					Reflect.setField(dWgt, "rebuildList", false);
					
					System.iterateWidgets(cast(dWgt, Options).box, function (w:Dynamic) if (Std.is(w, Toggle)) StablexUIMod.applyDefaults(w));
				}
				else if (Std.is(dWgt, StateButton))
					cast(dWgt, StateButton).updateState();
				else if (Std.is(dWgt, TabStack))
					System.iterateWidgets(dWgt, function (w:Dynamic) if (!Std.is(w, TabStack)) StablexUIMod.applyDefaults(w));
				else if (Std.is(dWgt, Progress))
					cast(dWgt, Progress).value = cast(dWgt, Progress).value;
				
				if (wgt.tip != null)
					StablexUIMod.applyDefaults(wgt.tip);
				
				wgt.refresh();
			}
		}
	}
	
	public static function setRtxmlMod () : Void { // workaround to ignore elements with unregistered class
		var origProcessXml:Xml->Interp->RTXml = Reflect.field(RTXml, "processXml");
		
		Reflect.setField(RTXml, "processXml", function (node:Xml, interp:Interp = null) : RTXml {
			try {
				return origProcessXml(node, interp);
			}
			catch (ex:Dynamic) {
				var cache:RTXml = new RTXml(interp);
				cache.cls = RTXml.getImportedClass("Widget");
				
				return cache;
			}
		});
	}
}
