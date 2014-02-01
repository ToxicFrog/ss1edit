class('GS_Item','GS_Class',{
	ReadSuper = function(this,fin)
		fin:read(2)
	end;
	Read = function(this,fin)
		fin:read(1)
	end;
	SaveSuper = function(this,fout)
		fwrite(fout,2,0)
	end;
	Save = function(this,fout)
		fwrite(fout,1,0)
	end;
})

class('GS_QuestItem','GS_Item',{
	Read = function(this,fin)
		fin:read(2)
	end;
	Save = function(this,fout)
		fwrite(fout,2,0)
	end;
})

class('GS_CyberItem','GS_Item',{
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
		p = new.GS_Item.Display(self, parent)
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
