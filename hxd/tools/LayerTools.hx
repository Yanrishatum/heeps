package hxd.tools;

import h2d.Object;
import h2d.Layers;

@:access(h2d.Layers)
@:access(h2d.Object)
class LayerTools
{
  
	/**
		Adds an Object to specified layer and specified index of that layer.
	**/
  public static function addAt(l:Layers, s:Object, layer:Int, index:Int):Void
  {
		if ( layer >= l.layerCount ) {
			l.add(s, layer);
			return;
		}

		if ( s.parent == l ) {
			var old = s.allocated;
			s.allocated = false;
			l.removeChild(s);
			s.allocated = old;
		}
		if ( index <= 0 ) {
			super_addChildAt(l, s, layer == 0 ? 0 : l.layersIndexes[layer - 1]);
		} else {
			var start = layer == 0 ? 0 : l.layersIndexes[layer - 1];
			if (l.layersIndexes[layer] - start >= index)
				super_addChildAt(l, s, l.layersIndexes[layer]);
			else
				super_addChildAt(l, s, start + index);
		}

		for ( i in layer...l.layerCount )
			l.layersIndexes[i]++;
  }
  
	/**
		Moves Object to specified index on it's layer.
	**/
	public static function moveChild( l:Layers, s : Object, index : Int ) {
		for( i in 0...l.children.length )
			if ( l.children[i] == s ) {
				var pos = 0;
				for ( l in l.layersIndexes )
					if ( l > i ) {
						if ( index >= (l - pos) ) index = l - pos - 1;
						break;
					} else {
						pos = l;
					}
				if ( (i - pos) > index ) { // under
					if ( index > 0 ) pos += index;
					var p = i;
					while ( p > pos ) {
						l.children[p] = l.children[p - 1];
						p--;
					}
				} else { // over
					pos += index;
					for ( p in i...pos )
						l.children[p] = l.children[p + 1];
				}
				l.children[pos] = s;
				if ( s.allocated )
					s.onHierarchyMoved(false);
				return;
			}
	}
  
	/**
		Finds the index of a child in it's layer.  
		Always returns -1 if provided Object is not a child of Layer.
	**/
	public static function getChildLayerIndex( l:Layers, s : Object ) : Int {
		if ( s.parent != l ) return -1;

		var index = l.children.indexOf(s);
		for ( i in 0...l.layerCount )
			if ( l.layersIndexes[i] > index ) return (i == 0 ? index : index - l.layersIndexes[i - 1]);
		return -1;
	}

  // Since we don't have access to super. - copypaste the thing.
  static function super_addChildAt(l:Layers, s:Object, pos:Int):Void
  {
		if( pos < 0 ) pos = 0;
		if( pos > l.children.length ) pos = l.children.length;
		var p : Object = l;
		while( p != null ) {
			if( p == s ) throw "Recursive addChild";
			p = p.parent;
		}
		if( s.parent != null ) {
			// prevent calling onRemove
			var old = s.allocated;
			s.allocated = false;
			s.parent.removeChild(s);
			s.allocated = old;
		}
		l.children.insert(pos, s);
		if( !l.allocated && s.allocated )
			s.onRemove();
		s.parent = l;
		s.parentContainer = l.parentContainer;
		s.posChanged = true;
		// ensure that proper alloc/delete is done if we change parent
		if( l.allocated ) {
			if( !s.allocated )
				s.onAdd();
			else
				s.onHierarchyMoved(true);
		}
		l.onContentChanged();
  }

}