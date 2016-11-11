package rn.stablex.designer;

import ru.stablex.ui.*;
import ru.stablex.ui.skins.*;

class SkinParser {
	public static function parse (xml:Xml) : SkinInfo {
		if (xml.nodeType == Xml.XmlType.Element) {
			var skinClass:Dynamic = Type.resolveClass(xml.nodeName.split(":")[1]);
			
			if (skinClass == null)
				skinClass = Type.resolveClass("ru.stablex.ui.skins." + xml.nodeName.split(":")[1]);
			
			var skin:Skin = Type.createInstance(skinClass, []);
			
			System.setGuiObjProperties(skin, [for (a in xml.attributes()) { name: a, value: xml.get(a) }]);
			
			return { name: xml.nodeName.split(":")[0], skin: skin };
		}
		
		return null;
	}
}
