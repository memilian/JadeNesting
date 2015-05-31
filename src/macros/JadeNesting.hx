package macros;

#if (macro && !doc_gen)
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Expr.FieldType;
import haxe.macro.Expr.Field;
import haxe.macro.Expr.Function;
import tink.MacroApi;

using tink.MacroApi;

/**
 * ...
 * @author memilian
 */
class JadeNesting
{
	macro public static function build(nestFunctionName : String) : Array<Field> {

		var fields = Context.getBuildFields();

		for (field in fields) {
			switch(field.kind) {
				case FFun(func):
					func.expr = func.expr.transform(function(e) {
						return switch(e) {
							case macro @jade($root) $block :
								var transformer = new NestingTransformer(nestFunctionName);
								transformer.setRoot(macro $root);
								e.transform(transformer.doTransform);
							case macro @jade $block :
								var transformer = new NestingTransformer(nestFunctionName);
								e.transform(transformer.doTransform);
							default:
								 e;
						}
					});
				default:
			}
		}
		return fields;
	}
	

	
	static function log(e : Dynamic, ?pos: Position) {
		Context.warning(Std.string(e), pos != null ? pos : Context.currentPos());
	}
}


#end