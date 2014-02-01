class('GS_Dummy','GS_Class',{
	Length = 3272;
	CommonLength = 12852 - (299*27);
	Data = false;
	CommonData = false;
	
	ReadCommon = function(this, fin)
		--CommonData = fin:read(CommonLength)
	end;
	ReadSuper = function(this, fin)
		Data = fin:read(Length)
	end;
	Read = function() end;
	
	SaveCommon = function(this,fout)
		--fout:write(CommonData)
		--fout:write(string.char(255))
	end;
	SaveSuper = function(this,fout)
		fout:write(Data)
		--fout:write(string.char(255))
	end;
	Save = function() end;
})

class('GS_Empty','GS_Class',{
	ReadSuper = function() end;
	Read = function() end;
	SaveSuper = function() end;
	Save = function() end;
})
