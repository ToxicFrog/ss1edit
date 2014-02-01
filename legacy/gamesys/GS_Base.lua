class('GS_Class',{
	nameLongI = 0;
	nameID = "__FIXME_NAMEID__";
	nameLong = function(this)
		return (RES and RES(x('24')) and RES(x('24'))(nameLongI))
			or (GS and GS.LongNames and GS.LongNames[nameLongI])
			or "__FIXME_LONGNAME__"
	end;
	nameShort = function(this)
		return (RES and RES(x('86D')) and RES(x('86D'))(nameLongI))
			or (GS and GS.ShortNames[nameLongI])
			or "__FIXME_SHORTNAME__"
	end;
	displayPane = false;
	mass = 0;
	hp = 0;
	armour = 0;
	rendertype = 0;
	vulnerable = {
		impact = 	{ 0, false };
		energy = 	{ 1, false };
		EMP = 		{ 2, false };
		ion = 		{ 3, false };
		gas = 		{ 4, false };
		tranq = 	{ 5, false };
		needle = 	{ 6, false };
		['7'] = 	{ 7, false };
	};
	special_vuln = 0;
	defence = 0;
	flags = {
		inventory =	{ 0, false };
		touchable = { 1, false };
		['2'] = 	{ 2, false };
		['3'] = 	{ 3, false };
		
		consumable ={ 4, false };
		opaque =	{ 5, false };
		['6'] = 	{ 6, false };
		['7'] = 	{ 7, false };
		openable =	{ 8, false };
		static = 	{ 9, false };
		explosion =	{ 10, false };
		xplodehit = { 11, false };
		['C'] = 	{ 12, false };
		['D'] = 	{ 13, false };
		['E'] = 	{ 14, false };
		['F'] = 	{ 15, false };
	};
	model = 0;
	frames = 0;
	UNKNOWN_ONE = 0;
	UNKNOWN_TWO = 0;
	UNKNOWN_THREE = 0;
	UNKNOWN_FOUR = 0;
	UNKNOWN_FIVE = 0;
	
	Display = function(self, parent)
		local p = FXPacker.Create(parent, FX.LAYOUT_FILL_X + FX.LAYOUT_FILL_Y)
		displayPane = p

		self:LabeledTextInt(p, "Mass", 8, 'mass')
		self:LabeledTextInt(p, "HP", 8, 'hp')
		self:LabeledTextInt(p, "Armour", 8, 'armour')
		self:LabeledTextInt(p, "Defence", 8, 'defence')
		self:LabeledTextInt(p, "Special Vulnurability", 8, 'special_vuln')
		self:LabeledTextInt(p, "Render Type", 8, 'rendertype')
		self:LabeledTextInt(p, "3d Model", 8, 'model')
		self:LabeledTextInt(p, "Framecount", 8, 'frames')
		-- render type: dropdown
		-- vulnerable: flags
		local l = FXMatrix.Create(p, 4, FX.LAYOUT_SIDE_TOP + FX.LAYOUT_FILL_X + FX.MATRIX_BY_COLUMNS)
		FXLabel.Create(l, "Vulnerable", FX.LAYOUT_SIDE_LEFT + FX.LAYOUT_FILL_X)
		for k,v in pairs(vulnerable) do
			FXCheckButton.Create(l, tostring(k), nil, nil, FX.CHECKBUTTON_NORMAL + FX.LAYOUT_SIDE_RIGHT)
			:setCheck(b2i(v[2]))
		end
		-- flags: flags
		local l = FXMatrix.Create(p, 4, FX.LAYOUT_SIDE_TOP + FX.LAYOUT_FILL_X + FX.MATRIX_BY_COLUMNS)
		FXLabel.Create(l, "Flags", FX.LAYOUT_SIDE_LEFT + FX.LAYOUT_FILL_X)
		for k,v in pairs(flags) do
			FXCheckButton.Create(l, tostring(k), nil, nil, FX.CHECKBUTTON_NORMAL + FX.LAYOUT_SIDE_RIGHT)
			:setCheck(b2i(v[2]))
		end
		return p
	end;
	
	ReadCommon = function(self,fin)
		local vulnmask,flagmask
		mass,
		hp,
		armour,
		rendertype = freadint(fin,4,2,1,1)
		UNKNOWN_ONE,
		UNKNOWN_TWO,
		vulnmask,
		special_vuln = freadint(fin,4,2,1,1)
		UNKNOWN_THREE,
		defence,
		UNKNOWN_FOUR,
		flagmask,
		model,
		frames,
		UNKNOWN_FIVE = freadint(fin,2,1, 1,2 ,2,1,2)
		for k,v in pairs(self.vulnerable) do
			if bit.bset(vulnmask,v[1]) then
				v[2] = true
			end
		end
		for k,v in pairs(self.flags) do
			if bit.bset(flagmask,v[1]) then
				v[2] = true
			end
		end
	end;
	
	SaveCommon = function(self,fout)
		local vulnmask,flagmask = 0,0
		for k,v in pairs(flags) do
			if v[2] then
				flagmask = bit.bset(flagmask,v[1],1)
			end
		end
		for k,v in pairs(vulnerable) do
			if v[2] then
				vulnmask = bit.bset(vulnmask,v[1],1)
			end
		end
		-- set up masks
		fwrite(fout,
			4,mass,
			2,hp,
			1,armour,
			1,rendertype,
			4,UNKNOWN_ONE,
			2,UNKNOWN_TWO,
			1,vulnmask,
			1,special_vuln,
			2,UNKNOWN_THREE,
			1,defence,
			1,UNKNOWN_FOUR,
			2,flagmask,
			2,model,
			1,frames,
			2,UNKNOWN_FIVE)
	end;
	
	SaveSuper = function(self,fout)
		fwrite(fout,1,0)
	end;
	
	Save = function(self,fout)
		fwrite(fout,1,0)
	end;
	
	ReadSuper = function(self,fin)
		freadint(fin,1)
	end;
	
	Read = function(self,fin)
		freadint(fin,1)
	end;
	
	ClearDisplay = function(self)
		displayPane:delete()
	end;

	LabeledTextInt = function(this, parent, label, width, key)
		local l = FXHorizontalFrame.Create(parent, FX.LAYOUT_SIDE_TOP + FX.LAYOUT_FILL_X)
		FXLabel.Create(l, label, FX.LAYOUT_SIDE_LEFT)
		FXVerticalSeparator.Create(l,FX.LAYOUT_FILL_X + FX.LAYOUT_FILL_Y)
		local t = FXTextField.Create(l, width, l, FXTopWindow.ID_LAST+1, FX.LAYOUT_SIDE_RIGHT + FX.TEXTFIELD_INTEGER)
		t:setText(tostring(this[key] or key))
		l:connect_event(FX.SEL_COMMAND,
			FXTopWindow.ID_LAST+1,
			function() end)
		l:connect_event(FX.SEL_CHANGED,
			FXTopWindow.ID_LAST+1,
			function(obj,sel,data)
				if this[key] then
					this[key] = tonumber(obj:getText())
				end
			end)
		return t
	end;

})
