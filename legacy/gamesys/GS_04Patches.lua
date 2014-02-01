class('GS_Patch','GS_Class',{
	ReadSuper = function(this,fin)
		fin:read(24)
	end;
	Read = function() end;
	SaveSuper = function(this,fout)
		fwrite(fout,24,0)
	end;
	Save = function() end;
})
