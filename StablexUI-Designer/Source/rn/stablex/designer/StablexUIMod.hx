package rn.stablex.designer;

import hscript.Interp;

import ru.stablex.ui.*;
import ru.stablex.ui.events.*;
import ru.stablex.ui.layouts.*;
import ru.stablex.ui.misc.*;
import ru.stablex.ui.skins.*;
import ru.stablex.ui.transitions.*;
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
		
		for (p in ["", "ru.stablex.", "ru.stablex.ui.events.", "ru.stablex.ui.layouts.", "ru.stablex.ui.misc.", "ru.stablex.ui.skins.", "ru.stablex.ui.transitions.", "ru.stablex.ui.widgets."])
			if ((resCls = Type.resolveClass(p + className)) != null)
				break;
		
		return resCls;
	}
	
	public static function setRtDefaults (dWgt:Dynamic) : Void { // set defaults for widgets at runtime
		for (defName in cast(dWgt, Widget).defaults.split(",")) {
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
				
				cast(dWgt, Widget).refresh();
				
				if (Std.is(dWgt, StateButton))
					cast(dWgt, StateButton).updateState();
			}
		}
	}
}
