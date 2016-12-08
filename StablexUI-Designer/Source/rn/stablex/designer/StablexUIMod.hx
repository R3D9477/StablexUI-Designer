package rn.stablex.designer;

import hscript.Interp;
import ru.stablex.ui.RTXml;
import ru.stablex.ui.UIBuilder;
import ru.stablex.ui.widgets.*;

using Lambda;
using rn.typext.ext.XmlExtender;
using rn.typext.ext.IterExtender;

class StablexUIMod {
	public static var rtDefaults:Xml;
	
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
	
	public static function resolveClass (className:String) : Class<Dynamic> {
		var resCls:Class<Dynamic> = null;
		
		for (p in ["", "ru.stablex.", "ru.stablex.events.", "ru.stablex.layouts.", "ru.stablex.misc.", "ru.stablex.ui.skins.", "ru.stablex.transitions.", "ru.stablex.ui.widgets."])
			if ((resCls =  Type.resolveClass(p + className)) != null)
				break;
		
		return resCls;
	}
	
	public static function setRtDefaults (dWgt:Dynamic) : Void { // set defaults for widgets at runtime
		var defsX:Xml = StablexUIMod.rtDefaults.getByXpath('//Defaults/${Type.getClassName(Type.getClass(dWgt)).split(".").pop()}/Default');
		
		if (defsX != null) {
			var wgtX:Xml = System.wgtUiXmlMap.get(dWgt);
			
			if (wgtX != null) {
				System.setGuiObjProperties(
					dWgt,
					defsX.attributes()
						.array()
						.filter(function (attr:String) : Bool {
							if (attr == "w" || attr.indexOf("width") > -1)
								return !(wgtX.exists("w") || wgtX.exists("width") || wgtX.exists("widthPt"));
							else if (attr == "h" || attr.indexOf("height") > -1)
								return !(wgtX.exists("h") || wgtX.exists("height") || wgtX.exists("heightPt"));
							
							return !wgtX.exists(attr);
						})
						.map(function (attr:String) : Dynamic return { name: attr, value: defsX.get(attr) })
				);
				
				cast(dWgt, Widget).refresh();
				
				if (Std.is(dWgt, StateButton))
					cast(dWgt, StateButton).updateState();
			}
		}
	}
}
