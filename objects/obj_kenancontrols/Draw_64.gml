var _iter = new KConIterator ()

var _el = undefined

while !_iter.Done()
{
	_el = _iter.Next();
	_el.Update();
}