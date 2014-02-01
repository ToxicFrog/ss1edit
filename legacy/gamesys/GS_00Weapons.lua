class('GS_Weapon','GS_Class',{
	ROF = 0;
	clips = { false, false, false, false };
	clipst = 0;
	ReadSuper = function(self,fin)
		self.ROF = freadint(fin,1)
		do
			local clipmask = freadint(fin,1)
			clipst = bit.rshift(clipmask,4)
			for i=1,4,1 do
				if bit.bset(clipmask,i-1) then
					clips[i] = { true }
				end
			end
		end
	end;
	
	SaveSuper = function(this,fout)
		local clipmask = 0;
		clipmask = bit.bor(clipmask,bit.lshift(clipst,4))
		for i=1,4,1 do
			if clips[i] then
				clipmask = bit.bset(clipmask,i-1,1)
			end
		end
		fwrite(fout,
			1,ROF,
			1,clipmask)
	end;
	
	Display = function(self, parent)
		local st
		local p = new.GS_Class.Display(self, parent)
		-- rate of fire
		self:LabeledTextInt(p, "Rate of Fire", 8, 'ROF')
		-- clips
		self:LabeledTextInt(p, "Clip Subtype", 1, 'clipst')
		local l = FXHorizontalFrame.Create(p, FX.LAYOUT_SIDE_TOP + FX.LAYOUT_FILL_X)
		FXLabel.Create(l, "Accepts Clips", FX.LAYOUT_SIDE_LEFT + FX.LAYOUT_FILL_X)
		FXVerticalSeparator.Create(l,FX.LAYOUT_FILL_X + FX.LAYOUT_FILL_Y)
		for i=1,4,1 do
			FXCheckButton.Create(l, tostring(i), l, i+FXTopWindow.ID_LAST, FX.CHECKBUTTON_NORMAL + FX.LAYOUT_SIDE_RIGHT)
			:setCheck(b2i(clips[i]))
			l:connect_event(FX.SEL_COMMAND,
				i+FXTopWindow.ID_LAST,
				function(obj)
					clips[i] = obj:getCheck() == 1
				end)
		end
		return p
	end;
})

class('GS_SemiAutoWeapon','GS_Weapon',{})

class('GS_FullAutoWeapon','GS_Weapon',{})

class('GS_DirectDamageWeapon', 'GS_Weapon', {
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
	unknown = 0;
	penetration = 0;
	Read = function(self,fin)
		local damagemask
		self.damage,self.offence,
		damagemask,self.special,
		self.unknown,self.penetration
			= freadint(fin,2,1,1,1,2,1)

		do	-- damage types
			for k,v in pairs(self.attacks) do
				if bit.bset(damagemask,v[1]) then
					v[2] = true
				end
			end
		end
	end;
	
	Save = function(self,fout)
		local damagemask = 0;
		for k,v in pairs(attacks) do
			if v[2] then
				damagemask = bit.bset(damagemask,v[1],1)
			end
		end
		print("fwrite")
		fwrite(fout,
			2,damage,
			1,offence,
			1,damagemask,
			1,special,
			2,unknown,
			1,penetration)
	end;
	
	Display = function(self, parent)
		local p = new.GS_Weapon.Display(self, parent)
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

		self:LabeledTextInt(p, "(unknown)", 16, 'unknown')
		return p
	end;
})

class('GS_ProjectileWeapon','GS_DirectDamageWeapon',{
	projectile = { 0,0,0 };
	unknown_2 = 0;
	Read = function(self,fin)
		new.GS_DirectDamageWeapon.Read(self,fin)
		freadint(fin,1)
		self.projectile[3],
		self.projectile[2],
		self.projectile[1],
		self.unknown_2 = freadint(fin,1,1,1,4)
	end;
	
	Save = function(self,fout)
		new.GS_DirectDamageWeapon.Save(self,fout)
		fwrite(fout,
			1,6,
			1,projectile[3],
			1,projectile[2],
			1,projectile[1],
			4,unknown_2)
	end;
	
	Display = function(self, parent)
		local p = new.GS_DirectDamageWeapon.Display(self, parent)
		local l = FXHorizontalFrame.Create(p, FX.LAYOUT_SIDE_TOP + FX.LAYOUT_FILL_X)
		FXLabel.Create(l, "Projectile", FX.LAYOUT_SIDE_LEFT + FX.LAYOUT_FILL_X)
		FXVerticalSeparator.Create(l,FX.LAYOUT_FILL_X + FX.LAYOUT_FILL_Y)
		for i=1,3,1 do
			FXTextField.Create(l, 1, l, i+FXTopWindow.ID_LAST, FX.LAYOUT_SIDE_RIGHT + FX.TEXTFIELD_INTEGER)
				:setText(projectile[i])
			l:connect_event(FX.SEL_COMMAND,
				i+FXTopWindow.ID_LAST,
				function() end)
			l:connect_event(FX.SEL_CHANGED,
				i+FXTopWindow.ID_LAST,
				function(obj)
					projectile[i] = tonumber(obj:getText())
				end)
		end
		self:LabeledTextInt(p, "(unknown)", 16, 'unknown_2')
		return p
	end;
})

class('GS_EnergyWeapon','GS_DirectDamageWeapon',{
	energyUse = 0;
	kickback = 0;
	range = 0;
	unknown_2 = 0;
	Read = function(self,fin)
		new.GS_DirectDamageWeapon.Read(self,fin)
		self.energyUse,
		self.kickback,
		self.range,
		self.unknown_2 = freadint(fin,1,1,1,2)
	end;
	Save = function(self,fout)
		new.GS_DirectDamageWeapon.Save(self,fout)
		fwrite(fout,
			1,energyUse,
			1,kickback,
			1,range,
			2,unknown_2)
	end;	
	Display = function(self, parent)
		local p = new.GS_DirectDamageWeapon.Display(self, parent)
		self:LabeledTextInt(p, "Energy Use", 16, 'energyUse')
		self:LabeledTextInt(p, "Recoil", 16, 'kickback')
		self:LabeledTextInt(p, "Range", 16, 'range')
		self:LabeledTextInt(p, "(unknown)", 16, 'unknown_2')
		return p
	end;
})

class('GS_EnergyProjectileWeapon','GS_DirectDamageWeapon',{
	energyUse = 0;
	projectile = { 0,0,0 };
	unknown_2 = 0;
	unknown_3 = 0;
	Read = function(self,fin)
		new.GS_DirectDamageWeapon.Read(self,fin)
		self.energyUse = freadint(fin,1)
		unknown_2,
		self.projectile[3],
		self.projectile[2],
		self.projectile[1] = freadint(fin,4,1,1,1)
		freadint(fin,1)
		self.unknown_3 = freadint(fin,1)
	end;	
	Save = function(self,fout)
		new.GS_DirectDamageWeapon.Save(self,fout)
		fwrite(fout,
			1,energyUse,
			4,unknown_2,
			1,projectile[3],
			1,projectile[2],
			1,projectile[1],
			1,0,
			1,unknown_3)
	end;
	Display = function(self, parent)
		local p = new.GS_DirectDamageWeapon.Display(self, parent)
		self:LabeledTextInt(p, "Energy Use", 16, 'energyUse')
		local l = FXHorizontalFrame.Create(p, FX.LAYOUT_SIDE_TOP + FX.LAYOUT_FILL_X)
		FXLabel.Create(l, "Projectile", FX.LAYOUT_SIDE_LEFT + FX.LAYOUT_FILL_X)
		FXVerticalSeparator.Create(l,FX.LAYOUT_FILL_X + FX.LAYOUT_FILL_Y)
		for i=1,3,1 do
			FXTextField.Create(l, 1, l, i+FXTopWindow.ID_LAST, FX.LAYOUT_SIDE_RIGHT + FX.TEXTFIELD_INTEGER)
				:setText(projectile[i])
			l:connect_event(FX.SEL_CHANGED,
				i+FXTopWindow.ID_LAST,
				function(obj)
					projectile[i] = tonumber(obj:getText())
				end)
		end
		self:LabeledTextInt(p, "(unknown)", 16, 'unknown_2')
		return p
	end;
})
