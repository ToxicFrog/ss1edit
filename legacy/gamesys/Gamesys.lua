require('GS_Base')
require('GS_00Weapons')
require('GS_01Ammo')
require('GS_02Projectiles')
require('GS_03Explosives')
require('GS_04Patches')
require('GS_05Hardware')
require('GS_06Software')
require('GS_07Fixtures')
require('GS_08Items')
require('GS_09Switches')
require('GS_99Dummy')

-- for nametable lookups
-- 'RES' is a top-level file and will thus load any other libraries it needs
require('RES')

class('Gamesys',{
	LOADED = false;
	gs = {};

	__call = function(this, gtype, subtype, gclass)
		if type(gtype) == 'table' then
			return this(unpack(gtype))
		end
		if not gclass then return this:Size(gtype, subtype) end
		return this.gs[gtype][subtype][gclass]
	end;

	Size = function(this, type, subtype)
		local sizes = {
			n=16;
			{ n=6, 5,2,2,2,3,2; }; -- weapons			16	16
			{ n=7, 2,2,3,2,2,2,2; };	-- ammo 		15	31
			{ n=3, 6,16,2; }; -- projectiles			24	55
			{ n=2, 5,3; }; -- explosives				 8	63
			{ n=1, 7; }; -- patches 					 7	70
			{ n=2, 5,10; }; -- hardware					15	85
			{ n=6, 7,3,4,5,2,1; }; -- software 			22	107
			{ n=8, 9,10,11,4,9,8,16,10; }; -- fixtures	77	184
			{ n=8, 8,10,15,6,12,12,9,8; }; -- items		80	264
			{ n=6, 9,7,3,11,2,3; }; -- switches 		35	299
			{ n=5, 9,10,7,5,10 }; -- doors
			{ n=1, 34 }; -- animations
			{ n=3, 13,1,5 };
			{ n=7, 3,3,4,8,13,7,8 }; -- containers
			{ n=5, 9,12,7,7,2 }; -- critters
			{ n=1, 1; }; -- LAST_CLASS
		}
		if not type then
			return sizes.n;
		elseif not subtype then
			return sizes[type+1].n;
		else
			return sizes[type+1][subtype+1];
		end
	end;

	Name = function(this,t,st)
		local names = {
			"Weapons",
			"Ammo",
			"Projectiles",
			"Explosives",
			"Patches",
			"Hardware",
			"Software",
			"Fixtures",
			"Items",
			"Switches",
			"Doors",
			"Animations",
			"Triggers",
			"Containers",
			"Critters",
			"LAST_CLASS";

			Weapons = {
				"Semi-Automatic",
				"Automatic",
				"Projectile",
				"Melee",
				"Beam",
				"Energy-Projectile"
			};
			Ammo = {
				"Pistol",
				"Dartgun",
				"Magnum & Riot Gun",
				"Mk3 Assault Rifle",
				"Flechette Rifle",
				"Skorpion",
				"Magpulse & Railgun"
			};
			Projectiles = {
				"Tracers",
				"Projectiles",
				"Seekers"
			};
			Explosives = {
				"Grenades",
				"Explosives"
			};
			Patches = {
				"Patches";
			};
			Hardware = {
				"Vision Modes",
				"Implants"
			};
			Software = {
				"Weapons";
				"Defences";
				"Utilities";
				"Non-C/Space";
				"Information";
				"???";
			};
			Fixtures = {
				"Electronics";
				"Furniture";
				"Text & Screens";
				"Lights";
				"Shiny Things";
				"Non-Shiny Things";
				"Plants";
				"Terrain";
			};
			Items = {
				"Junk";
				"Debris";
				"Corpses & Body Parts";
				"Inventory Items";
				"Access Cards";
				"C/Space Items & Scenery";
				"Stains & Decals";
				"Quest Items";
			};
			Switches = {
				"Switches";
				"Receptacles";
				"Terminals";
				"Panels";
				"Vending Machines";
				"Cybertoggles";
			};
			Doors = {
				"Heavy Doors";
				"Doorways";
				"Energy Doors";
				"Elevator Doors";
				"Other Doors";
			};
			Animations = {
				"(unknown subtypes)"
			};
			Triggers = {
				"Triggers",
				"Tripbeam",
				"Marks"
			};
			Containers = {
				"Crates",
				"Hazards",
				"Lab Equipment",
				"Corpses",
				"Destroyed Bots",
				"Destroyed Cyborgs",
				"Destroyed Programs"
			};
			Critters = {
				"Mutations",
				"Bots",
				"Cyborgs",
				"Programs",
				"Bosses"
			};
			LAST_CLASS = {
				"Dummy Class";
			};
		}
		if not st then
			return names[t+1] or tostring(t)
		else
			return names[names[t+1]] and names[names[t+1]][st+1] or tostring(st)
		end
	end;

	Init = function(this, root, menuroot, menu)

		this.LongNames = require('GS_LongNames')
		this.ShortNames = require('GS_ShortNames')

		local ID_LOADGS = FXTopWindow.ID_LAST +1
		local ID_SAVEGS = ID_LOADGS+1
		local ID_SAVEGSAS = ID_LOADGS+2
		local ID_LOADSTR = ID_LOADGS+3
		local ID_DUMMY = ID_LOADGS+4

		local gsmenu = FXMenuPane.Create(menuroot)
		local bLoad =
		FXMenuCommand.Create(gsmenu, "Load Gamesys...",nil,gsmenu,ID_LOADGS,0)
		FXMenuCommand.Create(gsmenu, "Save Gamesys",nil,gsmenu,ID_SAVEGS,0)
		FXMenuCommand.Create(gsmenu, "Save Gamesys As...",nil,gsmenu,ID_SAVEGSAS,0)
		FXMenuSeparator.Create(gsmenu)
		FXMenuCommand.Create(gsmenu, "Load Texture Properties...",nil,gsmenu,ID_DUMMY,0):disable()
		FXMenuCommand.Create(gsmenu, "Save Texture Properties",nil,gsmenu,ID_DUMMY,0):disable()
		FXMenuCommand.Create(gsmenu, "Save Texture Properties As...",nil,gsmenu,ID_DUMMY,0):disable()
		FXMenuTitle.Create(menu,"Gamesys",nil,gsmenu)

		sroot = FXSplitter.Create(root, FX.SPLITTER_NORMAL
			+ FX.LAYOUT_SIDE_TOP + FX.LAYOUT_FILL_X + FX.LAYOUT_FILL_Y)

		this.Tree = FXTreeList.Create(sroot, root, FXTopWindow.ID_LAST +1, FX.TREELIST_NORMAL
			+ FX.TREELIST_ROOT_BOXES + FX.TREELIST_SHOWS_LINES + FX.TREELIST_SHOWS_BOXES
			+ FX.LAYOUT_SIDE_LEFT + FX.LAYOUT_FILL_Y
			+ FX.LAYOUT_FIX_WIDTH, 0,0,256,0)

		this.Edit = FXScrollWindow.Create(
			FXGroupBox.Create(sroot, "Gamesys", FX.FRAME_RIDGE + FX.GROUPBOX_NORMAL
				+ FX.LAYOUT_FILL_X + FX.LAYOUT_FILL_Y),
			FX.LAYOUT_FILL_X + FX.LAYOUT_FILL_Y)

		-- buttons!
		gsmenu:connect_event(FX.SEL_COMMAND,
			ID_LOADGS,
			function(obj,sel,data)
				local fn = FXFileDialog.Create(root,"LOADGS")
					:getOpenFilename(root,"Load Gamesys","OBJPROP.DAT","*")
				if fn == "" then return end
				local fin = io.open(fn,"rb")
				if not fin then
					MsgBox.error(FX.MBOX_OK,"Load Gamesys","Unable to open "..fn.." for read.")
				else
					this:Load(fin)
					this.fName = fn
					this:Display()
					fin:close()
					bLoad:delete()
					LOADED = true
				end
			end)
		gsmenu:connect_event(FX.SEL_COMMAND,
			ID_SAVEGS,
			function(obj,sel,data)
				if not this.LOADED then
					MsgBox.error(FX.MBOX_OK,"Save Gamesys","No gamesys loaded.")
					return
				end
				local fout = io.open(this.fName,"wb")
				if not fout then
					MsgBox.error(FX.MBOX_OK,"Save Gamesys","Unable to open "..this.fName.." for write.")
				else
					this:Save(fout)
					fout:close()
				end
				MsgBox.Information(FX.MBOX_OK,"Save Gamesys","Gamesys saved.")
			end)
		gsmenu:connect_event(FX.SEL_COMMAND,
			ID_SAVEGSAS,
			function(obj,sel,data)
				if not this.LOADED then
					MsgBox.error(FX.MBOX_OK,"Save Gamesys As","No gamesys loaded.")
					return
				end
				local fn = FXFileDialog.Create(root,"SAVEGS")
					:getSaveFilename(root,"Save Gamesys","OBJPROP.DAT","*")
				if fn == "" then return end
				local fout = io.open(fn,"wb")
				if not fout then
					MsgBox.error(FX.MBOX_OK,"Save Gamesys As","Unable to open "..fn.." for write.")
				else
					this:Save(fout)
					fout:close()
				end			
			end)

		root:connect_event(FX.SEL_SELECTED,
			FXTopWindow.ID_LAST +1,
			function(obj, sel, data)
				local thingy = FX.pointer_to_object(data)
				if this.Link[thingy:getData()] then
					--Gamesys.Edit:setCurrent(Gamesys.Link[thingy:getData()].e)
					if this.Current then
						this.Current:ClearDisplay()
					end
					this.Link[thingy:getData()].gs:Display(this.Edit):create()
					this.Current = this.Link[thingy:getData()].gs
					this.Edit:getParent():setText(
						sprintf("[%s] %s (%s)",
							this.Link[thingy:getData()].gs.nameID,
							this.Link[thingy:getData()].gs:nameLong(),
							this.Link[thingy:getData()].gs:nameShort()
						))
				end
			end)
	end;

	New = function(this,t,st)
		local types = {
			{	n=6;	-- weapons
				new.GS_SemiAutoWeapon;
				new.GS_FullAutoWeapon;
				new.GS_ProjectileWeapon;
				new.GS_EnergyWeapon;
				new.GS_EnergyWeapon;
				new.GS_EnergyProjectileWeapon;
			};
			new.GS_AmmoClip;	-- all ammo uses the same base class
			{	n=3;	-- projectiles
				new.GS_TracerProjectile;
				new.GS_DumbProjectile;
				new.GS_HomingProjectile;
			};
			{	n=2;	-- explosives
				new.GS_Grenade;
				new.GS_Explosive;
			};
			new.GS_Patch;
			new.GS_Hardware;
			new.GS_Software;
			new.GS_Fixture;
			{
				n=8;
				new.GS_Item;
				new.GS_Item;
				new.GS_Item;
				new.GS_Item;
				new.GS_Item;
				new.GS_CyberItem;
				new.GS_Item;
				new.GS_QuestItem;
			};
			{
				n=6;
				new.GS_Class;
				new.GS_Class;
				new.GS_Class;
				new.GS_Class;
				new.GS_VendingMachine;
				new.GS_Class;
				new.GS_Class;
			};
			new.GS_Empty; -- doors
			new.GS_Empty; -- animations
			new.GS_Empty; -- triggers
			new.GS_Empty; -- containers
			new.GS_Empty; -- critters
			{	n=1;	-- LAST_CLASS
				new.GS_Dummy;
			};
		}

		if type(types[t+1]) == 'table' then
			if types[t+1]._new then
				return types[t+1]()
			else
				return types[t+1][st+1]()
			end
		else
			return nil
		end
	end;

	Display = function(this)
	
		for t=0,this:Size()-1,1 do
			tRoot = this.Tree:appendItemText(gsRootItem, this:Name(t))
			for st=0,this:Size(t)-1,1 do
				stRoot = this.Tree:appendItemText(tRoot, this:Name(t,st))
				for c=0,this:Size(t,st)-1,1 do
					cc = this.Tree:appendItemText(stRoot, this(t,st,c):nameLong(), nil, nil, this(t,st,c))
					--Gamesys[t][st][c]:Display(Gamesys.Edit)
					this.Link[cc:getData()] = { gs=this(t,st,c) }
				end
			end
		end
		this(0,0,0):Display(this.Edit):create()
		this.Current = this(0,0,0)
	end;

	Clear = function(this)
		this.LOADED = false
		local i = 0
		if this.Current then
			this.Current:ClearDisplay()
			this.Current = nil
		end
		this.gs = {}
		for t=0,this:Size()-1,1 do
			this.gs[t] = {}
			for st=0,this:Size(t)-1,1 do
				this.gs[t][st] = {}
				for c=0,this:Size(t,st)-1,1 do
					--printf("Creating gamesys entry %u:%u:%u\n", t, st, c)
					--if Gamesys[t][st][c] then Gamesys[t][st][c]:ClearDisplay() end
					this.gs[t][st][c] = this:New(t,st)
					this.gs[t][st][c].nameLongI = i
					this.gs[t][st][c].nameID = sprintf("%u:%u:%u",t,st,c)
					i = i+1
				end
			end
		end
		this.Tree:clearItems()
		this.Link = {}
	end;

	Load = function(this,fin)
		this.LOADED = true
		this:Clear()

		freadint(fin,4) -- header

		for t=0,this:Size()-1,1 do
			for st=0,this:Size(t)-1,1 do
				for c=0,this:Size(t,st)-1,1 do
					--printf("ReadSuper: %u:%u:%u @%u %s\n",t,st,c,fin:seek(),this(t,st,c)._name)
					this(t,st,c):ReadSuper(fin)
				end
			end
			for st=0,this:Size(t)-1,1 do
				for c=0,this:Size(t,st)-1,1 do
					--printf("Read: %u:%u:%u @%u %s\n",t,st,c,fin:seek(),this(t,st,c)._name)
					this(t,st,c):Read(fin)
				end
			end
		end
		for t=0,this:Size()-1,1 do
			for st=0,this:Size(t)-1,1 do
				for c=0,this:Size(t,st)-1,1 do
					--printf("ReadCommon: %u:%u:%u @%u %s\t",t,st,c,fin:seek(),this(t,st,c)._name)
					this(t,st,c):ReadCommon(fin)
					--printf("done\n")
				end
			end
		end
	end;

	Save = function(this, fout)
		fout:write(string.char(x('2d'),0,0,0)) -- header

		for t=0,this:Size()-1,1 do
			for st=0,this:Size(t)-1,1 do
				for c=0,this:Size(t,st)-1,1 do
					--printf("SaveSuper: %u:%u:%u\n",t,st,c)
					this(t,st,c):SaveSuper(fout)
				end
			end
			print('')
			for st=0,this:Size(t)-1,1 do
				for c=0,this:Size(t,st)-1,1 do
					--printf("Save: %u:%u:%u\n",t,st,c)
					this(t,st,c):Save(fout)
				end
			end
		end
		print('')
		for t=0,this:Size()-1,1 do
			for st=0,this:Size(t)-1,1 do
				for c=0,this:Size(t,st)-1,1 do
					--printf("SaveCommon: %u:%u:%u\n",t,st,c)
					this(t,st,c):SaveCommon(fout)
				end
			end
		end
		print('')
	end;
})





