class('GS_Projectile','GS_Class',{
	pflags = {
		glows	 =	{ 0, false };
		worldbounce= { 1, false };
		critterbounce={ 2, false };
		cspace =	{ 3, false };
	};
	ReadSuper = function(self,fin)
		local flagmask = freadint(fin,1)
		for k,v in pairs(pflags) do
			if bit.bset(flagmask,v[1]) then
				v[2] = true
			end
		end
	end;
	SaveSuper = function(self,fout)
		local flagmask = 0;
		for k,v in pairs(pflags) do
			if v[2] then
				flagmask = bit.bset(flagmask,v[1],1)
			end
		end
		fwrite(fout,1,flagmask)
	end;
	Display = function(self, parent)
		p = new.GS_Class.Display(self, parent)
		local l = FXMatrix.Create(p, 4, FX.LAYOUT_SIDE_TOP + FX.LAYOUT_FILL_X + FX.MATRIX_BY_COLUMNS)
		FXLabel.Create(l, "Flags", FX.LAYOUT_SIDE_LEFT + FX.LAYOUT_FILL_X)
		for k,v in pairs(pflags) do
			FXCheckButton.Create(l, tostring(k), l, v[1]+FXTopWindow.ID_LAST, FX.CHECKBUTTON_NORMAL + FX.LAYOUT_SIDE_RIGHT)
			:setCheck(b2i(v[2]))
			l:connect_event(FX.SEL_COMMAND,
				v[1]+FXTopWindow.ID_LAST,
				function(obj)
					v[2] = obj:getCheck() == 1
				end)
		end
		return p
	end;
})

class('GS_TracerProjectile','GS_Projectile',{
	Read = function(self,fin)
		fin:read(20) -- discard 20 zero bytes
	end;
	Save = function(self,fout)
		fwrite(fout,20,0)
	end;
})
class('GS_DumbProjectile','GS_Projectile',{
	red = 0;
	green = 0;
	blue = 0;
	Read = function(self,fin)
		red,green,blue = freadint(fin,2,2,2)
	end;
	Save = function(self,fout)
		fwrite(fout,
			2,red,
			2,green,
			2,blue)
	end;
	Display = function(self, parent)
		p = new.GS_Projectile.Display(self, parent)
		local l = FXHorizontalFrame.Create(p, FX.LAYOUT_SIDE_TOP + FX.LAYOUT_FILL_X)
		FXLabel.Create(l, "Color", FX.LAYOUT_SIDE_LEFT + FX.LAYOUT_FILL_X)
		FXVerticalSeparator.Create(l,FX.LAYOUT_FILL_X + FX.LAYOUT_FILL_Y)
		FXLabel.Create(l, "R", FX.LAYOUT_SIDE_LEFT + FX.LAYOUT_FILL_X)
		FXTextField.Create(l, 6, l, 1+FXTopWindow.ID_LAST, FX.LAYOUT_SIDE_RIGHT + FX.TEXTFIELD_INTEGER)
			:setText(red)
		FXLabel.Create(l, "G", FX.LAYOUT_SIDE_LEFT + FX.LAYOUT_FILL_X)
		FXTextField.Create(l, 6, l, 2+FXTopWindow.ID_LAST, FX.LAYOUT_SIDE_RIGHT + FX.TEXTFIELD_INTEGER)
			:setText(green)
		FXLabel.Create(l, "B", FX.LAYOUT_SIDE_LEFT + FX.LAYOUT_FILL_X)
		FXTextField.Create(l, 6, l, 3+FXTopWindow.ID_LAST, FX.LAYOUT_SIDE_RIGHT + FX.TEXTFIELD_INTEGER)
			:setText(blue)
		l:connect_event(FX.SEL_COMMAND,
			1+FXTopWindow.ID_LAST,
			function() end)
		l:connect_event(FX.SEL_COMMAND,
			2+FXTopWindow.ID_LAST,
			function() end)
		l:connect_event(FX.SEL_COMMAND,
			3+FXTopWindow.ID_LAST,
			function() end)
		l:connect_event(FX.SEL_CHANGED,
			1+FXTopWindow.ID_LAST,
			function(obj)
				red = tonumber(obj:getText())
			end)
		l:connect_event(FX.SEL_CHANGED,
			2+FXTopWindow.ID_LAST,
			function(obj)
				green = tonumber(obj:getText())
			end)
		l:connect_event(FX.SEL_CHANGED,
			3+FXTopWindow.ID_LAST,
			function(obj)
				blue = tonumber(obj:getText())
			end)
		return p
	end;
})
class('GS_HomingProjectile','GS_Projectile',{})
