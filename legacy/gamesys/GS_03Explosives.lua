class('GS_Grenade','GS_Class',{
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
	};
	special = 0;
	unknown_1 = 0;
	penetration = 0;
	unknown_2 = "";
	ReadSuper = function(self,fin)
		local damagemask
		
		damage, offence, damagemask,
		special, unused, penetration
			= freadint(fin,2,1,1,1,2,1)
		unknown_2 = fin:read(7)
		
		for k,v in pairs(attacks) do
			if bit.bset(damagemask,v[1]) then
				v[2] = true
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
			1,penetration)
		fout:write(unknown_2)
	end;
	Display = function(self, parent)
		local p = new.GS_Class.Display(self, parent)
		self:LabeledTextInt(p, "Damage", 8, 'damage')
		self:LabeledTextInt(p, "Offence", 8, 'offence')
		self:LabeledTextInt(p, "Penetration", 8, 'penetration')
		self:LabeledTextInt(p, "Special", 8, 'special')

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

		self:LabeledTextInt(p, "(unknown)", 16, 'unknown_1')
		self:LabeledTextInt(p, "(unknown)", 16, 'unknown_2')
		
		return p
	end;
})

class('GS_Explosive','GS_Grenade',{
	unknown_3 = 0;
	Read = function(this,fin)
		unknown_3 = freadint(fin,3)
	end;
	Save = function(this,fout)
		fwrite(fout,
			3,unknown_3)
	end;
	Display = function(self, parent)
		local p = new.GS_Grenade.Display(self, parent)

		self:LabeledTextInt(p, "(unknown)", 16, 'unknown_3')
		
		return p
	end;
})
