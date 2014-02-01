class('GS_AmmoClip','GS_Class',{
	damage = 0;
	offence = 0;
	attacks = {
		impact = 	{ 0, false };
		energy = 	{ 1, false };
		EMP = 		{ 2, false };
		ion = 		{ 3, false };
		gas = 		{ 4, false };
		tranq = 	{ 5, false };
		needle = 	{ 6, false };
		['7'] = 	{ 7, false };
	};
	special = 0;
	unused = 0;
	penetration = 0;
	rounds = 0;
	kickback = 0;
	unknown_1 = 0;
	range = 0;
	unknown_2 = 0;
	ReadSuper = function(self,fin)
		local damagemask
		
		damage, offence, damagemask,
		special, unused, penetration,
		rounds, kickback, unknown_1,
		range, unknown_2 = freadint(fin,2,1,1,1,2,1,1,1,2,1,1)
		
		do	-- damage types
			for k,v in pairs(attacks) do
				if bit.bset(damagemask,v[1]) then
					v[2] = true
				end
			end
		end
	end;
	SaveSuper = function(this,fout)
		local damagemask = 0;
		for k,v in pairs(attacks) do
			if v[2] then
				damagemask = bit.bset(damagemask,v[1],1)
			end
		end
		fwrite(fout,
			2,damage,
			1,offence,
			1,damagemask,
			1,special,
			2,unused,
			1,penetration,
			1,rounds,
			1,kickback,
			2,unknown_1,
			1,range,
			1,unknown_2)
	end;
	Display = function(self, parent)
		local p = new.GS_Class.Display(self, parent)
		self:LabeledTextInt(p, "Damage", 8, 'damage')
		self:LabeledTextInt(p, "Offence", 8, 'offence')
		self:LabeledTextInt(p, "Penetration", 8, 'penetration')
		self:LabeledTextInt(p, "Special", 8, 'special')

		self:LabeledTextInt(p, "Rounds", 8, 'rounds')
		self:LabeledTextInt(p, "Recoil", 8, 'kickback')
		self:LabeledTextInt(p, "Range", 8, 'range')

		local l = FXMatrix.Create(p, 4, FX.LAYOUT_SIDE_TOP + FX.LAYOUT_FILL_X + FX.MATRIX_BY_COLUMNS)
		FXLabel.Create(l, "Attacktypes", FX.LAYOUT_SIDE_LEFT + FX.LAYOUT_FILL_X)
		for k,v in pairs(attacks) do
			FXCheckButton.Create(l, tostring(k), l, v[1]+FXTopWindow.ID_LAST, FX.CHECKBUTTON_NORMAL + FX.LAYOUT_SIDE_RIGHT)
			:setCheck(b2i(v[2]))
			l:connect_event(FX.SEL_COMMAND,
				v[1]+FXTopWindow.ID_LAST,
				function(obj)
					v[2] = obj:getCheck() == 1
				end)
		end

		self:LabeledTextInt(p, "(unused)", 16, 'unused')
		self:LabeledTextInt(p, "(unknown)", 16, 'unknown_1')
		self:LabeledTextInt(p, "(unknown)", 16, 'unknown_2')
		
		return p
	end;
})
