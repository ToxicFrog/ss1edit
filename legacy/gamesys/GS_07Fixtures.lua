class('GS_Fixture','GS_Class',{
	ReadSuper = function(this,fin)
		fin:read(3)
	end;
	Read = function() end;
	SaveSuper = function(this,fout)
		fwrite(fout,3,0)
	end;
	Save = function() end;
})
