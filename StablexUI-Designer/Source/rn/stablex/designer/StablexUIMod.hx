package rn.stablex.designer;

import hscript.Interp;
import ru.stablex.ui.RTXml;
import ru.stablex.ui.UIBuilder;
import ru.stablex.ui.widgets.Widget;

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
	
	public static function setRtDefaults (wgt:Dynamic) : Void { // set defaults for widgets at runtime
		var defsX:Xml = StablexUIMod.rtDefaults.getByXpath('//Defaults/${Type.getClassName(Type.getClass(wgt)).split(".").pop()}/Default');
		
		if (defsX != null) {
			var wgtX:Xml = System.wgtUiXmlMap.get(wgt);
			
			System.setGuiObjProperties(
				wgt,
				defsX.attributes()
					.array()
					.filter(function (attr:String) : Bool return !wgtX.exists(attr))
					.map(function (attr:String) : Dynamic return { name: attr, value: defsX.get(attr) })
			);
		}
	}
}
