package rn.stablex.designer;

import hscript.Interp;
import ru.stablex.ui.RTXml;

class StablexUIMod {
	public static function setRtxmlMod () : Void { // to ignore elements with unregistered class
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
