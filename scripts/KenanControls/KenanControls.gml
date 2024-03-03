function kcon_add_element (_id, _el) 
{
	with obj_kenancontrols
	{
		_el.identity = _id
		ds_map_add(elements, _id, _el)
	}
	
	return _id
}

function kcon_save () 
{
	self.data = {}
	
	var _iter = new KConIterator ()

	var _el = undefined

	while !_iter.Done()
	{
		_el = _iter.Next();
		self.data[$ _el.identity] = _el.Serialize();
	}
	
	var _fl = file_text_open_write(game_save_id + "kcon_save.dat")
	file_text_write_string(_fl, json_stringify(self.data, false))
	file_text_close(_fl)
}

function kcon_load ()
{
	if !file_exists(game_save_id + "kcon_save.dat")
		return;
	
	var _fl = file_text_open_read(game_save_id + "kcon_save.dat")
	var _data = file_text_read_string(_fl)
	file_text_close(_fl)
	
	_data = json_parse(_data)
	
	var _vname = struct_get_names(_data)
	for (var i = 0; i < array_length(_vname); i++)
	{
		var _name = _vname[i];
		kcon_get(_name).Deserialize(_data[$ _name]);
	}
}

function kcon_get (_id)
{
	return obj_kenancontrols.elements[? _id];
}

function KConIterator () constructor
{
	self.index = 0
	
	static Done = function()
	{
		return self.index > ds_map_size(obj_kenancontrols.elements) - 1
	}
	
	static Next = function ()
	{
		if self.Done()
			return undefined;
		
		var _keys = ds_map_keys_to_array(obj_kenancontrols.elements)
		return obj_kenancontrols.elements[? _keys[self.index++]]
	}
}

function KConElement (_sprite, _x, _y, _action, _angle) constructor 
{
	self.identity = undefined
	self.sprite = _sprite
	self.action = _action
	self.pos = [_x, _y]
	self.relocating = false
	self.reloc_hold_time = 0
	self.scale = 1
	self.angle = _angle
	
	static Update = function ()
	{
	}
	
	static RelocateBegin = function ()
	{
	}
	
	static RelocateEnd = function ()
	{
	}
	
	static RelocateUpdate = function ()
	{
		var _sp_w = sprite_get_width(self.sprite)
		var _sp_h = sprite_get_height(self.sprite)
		
		var _ms = { x: device_mouse_x(0), y: device_mouse_y(0) }
		
		var _hov = point_in_rectangle(_ms.x, _ms.y, self.pos[0] - (_sp_w / 2), self.pos[1] - (_sp_h / 2), self.pos[0] + (_sp_w / 2), self.pos[1] + (_sp_h / 2))
		var _thresh = 60*2
		var _holding = device_mouse_check_button(0, mb_left)
		
		if _hov && self.reloc_hold_time < _thresh && _holding && !self.relocating
			self.reloc_hold_time ++
		else if (!_holding || !_hov) && self.reloc_hold_time < _thresh
			self.reloc_hold_time = 0
		
		if _holding && self.reloc_hold_time >= _thresh
		{
			self.relocating = true
			self.RelocateBegin()
		}
		
		self.scale = lerp(self.scale, (self.relocating+1), .3)
		
		if self.relocating
		{
			self.pos = [_ms.x, _ms.y]
			if !_holding
			{
				self.relocating = false
				self.reloc_hold_time = 0
				self.RelocateEnd()
			}
		}
	}

	static Serialize = function ()
	{
		return
		{
			pos: self.pos,
		};
	}
	
	static Deserialize = function (_data)
	{
		self.pos = _data.pos;
	}
}

function KConButton (_sprite, _x, _y, _action, _angle, _vkey, _hold = false) : KConElement(_sprite, _x, _y, _action, _angle) constructor
{
	var _sp_w = sprite_get_width(self.sprite)
	var _sp_h = sprite_get_height(self.sprite)
	
	static __CreateVkey = function (_x, _y, _vkey)
	{
		var _sp_w = sprite_get_width(self.sprite)
		var _sp_h = sprite_get_height(self.sprite)
		return virtual_key_add(_x - _sp_w / 2, _y - _sp_h / 2, _sp_w, _sp_h, _vkey)
	}
	
	self.vkey = 
	{
		virtual: self.__CreateVkey(_x, _y, _vkey),
		key: _vkey
	}
	self.press_check = _hold ? keyboard_check : keyboard_check_pressed;
	
	static Update = function ()
	{
		self.RelocateUpdate()
		var _press = keyboard_check(self.vkey.key)
		draw_sprite_ext(self.sprite, 0, self.pos[0], self.pos[1], self.scale, self.scale, self.angle, c_white, _press ? .6 : 1)
		
		if self.press_check(self.vkey.key)
			self.action(self)
	}
	
	static RelocateBegin = function ()
	{
		virtual_key_delete(self.vkey.virtual)
	}
	
	static RelocateEnd = function ()
	{
		self.vkey.virtual = self.__CreateVkey(self.pos[0], self.pos[1], self.vkey.key)
	}
}

function KConAnalog (_sprite, _x, _y, _action, _angle, _thumb_sprite) : KConElement(_sprite, _x, _y, _action, _angle) constructor
{	
	self.thumb_spr = _thumb_sprite
	self.thumb_off = { x: 0, y: 0 }
	self.dragging = false
	
	static Update = function ()
	{
		self.RelocateUpdate()
		draw_sprite_ext(self.sprite, 0, self.pos[0], self.pos[1], self.scale, self.scale, self.angle, c_white, 1)
		
		var _sp_w = sprite_get_width(self.sprite)
		var _sp_h = sprite_get_height(self.sprite)
		
		var _limit_w = _sp_w/2
		var _limit_h = _sp_h/2
		
		var _tx = self.pos[0] + self.thumb_off.x
		var _ty = self.pos[1] + self.thumb_off.y
		
		var _vtx = self.pos[0] + clamp(self.thumb_off.x, -_limit_w, _limit_w)
		var _vty = self.pos[1] + clamp(self.thumb_off.y, -_limit_h, _limit_h)
		
		var _tw = sprite_get_width(self.thumb_spr)
		var _th = sprite_get_height(self.thumb_spr)
		
		draw_sprite_ext(self.thumb_spr, 0, _vtx, _vty, self.scale, self.scale, self.angle, c_white, 1)
		
		var _ms = { x: device_mouse_x(0), y: device_mouse_y(0) }
		
		var _hovered = point_in_rectangle(_ms.x, _ms.y, _tx - (_tw / 2), _ty - (_th / 2), _tx + (_tw / 2), _ty + (_th / 2))
		
		if device_mouse_check_button(0, mb_left) && _hovered
			self.dragging = true
			
		else if !device_mouse_check_button(0, mb_left)
			self.dragging = false
		
		if self.dragging
		{
			self.thumb_off = 
			{
				x: (_ms.x - self.pos[0]),
				y: (_ms.y - self.pos[1]),
			}
			
			self.action(self.thumb_off.x / (_sp_w / 2), self.thumb_off.y / (_sp_h / 2))
		}
		else
		{
			self.thumb_off = { x: 0, y: 0 }
		}
	}
}