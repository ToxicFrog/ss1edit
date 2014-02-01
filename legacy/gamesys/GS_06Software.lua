class('GS_Software','GS_Class',{
	ReadSuper = function(this,fin)
		fin:read(5)
	end;
	Read = function() end;
	SaveSuper = function(this,fout)
		fwrite(fout,5,0)
	end;
	Save = function() end;
})
