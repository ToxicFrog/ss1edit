class('GS_Hardware','GS_Class',{
	ReadSuper = function(this,fin)
		fin:read(11)
	end;
	Read = function() end;
	SaveSuper = function(this,fout)
		fwrite(fout,11,0)
	end;
	Save = function() end;
})
