package rn.stablex.designer;

import ru.stablex.ui.RTXml;

using StringTools;
using rn.typext.ext.IterExtender;

class HxExpr {
	private static var interp = new hscript.Interp();
	
	public static function setVar (varName:String, varVal:Dynamic) : Void
		interp.variables.set(varName, varVal);
	
	public static function init () : Void {
		ru.stablex.ui.RTXml.parser = new hscript.Parser();
		interp = new hscript.Interp();
		
		for (extCls in System.extClsMap.keys().array())
			setVar(extCls.split(".").pop(), extCls);
		
		for (cls in RTXml.imports.keys())
			setVar("__ui__" + cls, RTXml.imports.get(cls));
	}
	
	public static function evaluate (hxExpr:String) : Dynamic
		return interp.execute(ru.stablex.ui.RTXml.parser.parseString(ru.stablex.ui.RTXml.Attribute.fillShortcuts(hxExpr)));
}
