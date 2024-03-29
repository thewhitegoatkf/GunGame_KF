class GunGame extends Deathmatch
config(GunGame);

struct sInterGunsList{ 	
	var string classPath;
	var class<KFWeapon> weaponClass;
	var string weaponSingleClassPath; //needed to compare dual weapon scoring
	//var float dmgMod,
};

var array<sInterGunsList> LoadedGunsList;
var config array <string > GunsList;
//reliable client function ClientReceiveAwardInfo(byte AwardID, PlayerReplicationInfo PRI, int Value)
event InitGame( string Options, out string ErrorMessage )
{
	Super.InitGame( Options, ErrorMessage );
	`log("GunGame game type initialized");
}

event PreBeginPlay()
{
	if(GunsList.length == 0)
		LoadDefaultsAndSave();
	
	PreLoadServerGuns();
	bDisablePickups=true;
	Super.PreBeginPlay();
}

event PostBeginPlay()
{
	Super.PostBeginPlay();
	SetGoalScore(LoadedGunsList.length-1);
}

event PostLogin( PlayerController NewPlayer )
{
	local KFPlayerController KFPC;
	local sInterGunsList list;

	Super.PostLogin(NewPlayer);
	if(WorldInfo.NetMode != NM_DedicatedServer ) //if not a server no need to pre-load
		return;

	KFPC = KFPlayerController(NewPlayer);
	ForEach LoadedGunsList(list)
		KFPC.ClientTriggerWeaponContentLoad(list.weaponClass);
}	

function PreLoadServerGuns()
{
	local sInterGunsList preload;
	local string classPath;
	local class<KFWeap_DualBase> DualClass;

	LoadedGunsList.Remove(0, LoadedGunsList.length);
	ForEach GunsList(classPath)
	{
		preload.classPath = classPath;
		preload.weaponClass = class<KFWeapon>(DynamicLoadObject(classPath, class'Class'));
		if(preload.weaponClass == none)
		{
			`log("GunGame: Failed to load:"@classPath@"removing from GunsList");
			GunsList.RemoveItem(classPath);
			preload.classPath = "";
			continue;
		}

		preload.weaponClass.static.TriggerAsyncContentLoad(preload.weaponClass);
		DualClass = class<KFWeap_DualBase>(preload.weaponClass);
		if(DualClass != none && DualClass.Default.SingleClass != none)
			preload.weaponSingleClassPath = PathName(DualClass.Default.SingleClass);
		else
			preload.weaponSingleClassPath = "";

		LoadedGunsList.AddItem(preload);
	}
}

function LoadDefaultsAndSave()
{
	bDisablePickups=true;
	GunsList.Remove(0, GunsList.length);
	GunsList.AddItem("KFGameContent.KFWeap_Pistol_9mm");
	GunsList.AddItem("KFGameContent.KFWeap_Pistol_Colt1911");
	GunsList.AddItem("KFGameContent.KFWeap_Pistol_Deagle");
	GunsList.AddItem("KFGameContent.KFWeap_Shotgun_M4");
	GunsList.AddItem("KFGameContent.KFWeap_AssaultRifle_FNFal");
	GunsList.AddItem("KFGameContent.KFWeap_Flame_Flamethrower");
	GunsList.AddItem("KFGameContent.KFWeap_Bow_Crossbow");
	SaveConfig();
}

function ScorePlayerKill(DMPlayerController Killer, DMPlayerController KilledPlayer, Pawn KilledPawn, class<DamageType> damageType)
{
	local GGPlayerReplicationInfo GGPRI;
	local class<KFDamageType> KFDT;
    local class<KFWeaponDefinition> KFWD; 
    
	GGPRI = GGPlayerReplicationInfo(Killer.PlayerReplicationInfo);

	KFDT = class<KFDamageType>(damageType);
	if(KFDT != none)
		KFWD = KFDT.Default.WeaponDef;

	if(GGPRI != none && Killer != none && Killer != KilledPlayer && KFWD != none)
	{
		if(IsCorrectLevelKill(GetGGLevel(GGPRI), KFWD))
		{
			`log("LevelUp: Player" @ GGPRI.PlayerName @ "To:" @ GGPRI.GunLevel);
			GGPRI.SetGunLevel(GGPRI.GunLevel+1);
			if(!MyDMGRI.bWarmupRound && GGPRI.GunLevel > GoalScore)
			{
				EndOfMatchWinner(Killer);
				return;
			}

			if(LastTopScore < GGPRI.GunLevel)
			{
				LastTopScore = GGPRI.GunLevel;
				MyDMGRI.TopScore = LastTopScore;
				UpdateGameSettings();
			}
			LevelUp(Killer, GGPRI);
		}
	}
	
}

function bool IsCorrectLevelKill(int GunLevel, class<KFWeaponDefinition> KFWD)
{
	local sInterGunsList GGLIST;

	GGLIST = LoadedGunsList[GunLevel];
	if((KFWD.Default.WeaponClassPath == GGLIST.classPath) || //check if killed by level weapon
	(GGLIST.weaponSingleClassPath != "" && GGLIST.weaponSingleClassPath == KFWD.Default.WeaponClassPath)) //check if it was dual weapon
		return true;
	return false;
}

function int GetGGLevel(GGPlayerReplicationInfo GGPRI)
{
	return Clamp(GGPRI.GunLevel, 0, LoadedGunsList.length-1);
}

function LevelUp(Controller Player, GGPlayerReplicationInfo GGPRI)
{
	local KFPawn KFP;
	
	KFP = KFPawn(Player.Pawn);

	if(KFP == none || !KFP.IsAliveAndWell())
		return;
	
	ClearInventory(KFP);
	
	AddWeapon(KFP, LoadedGunsList[GetGGLevel(GGPRI)].weaponClass);
	InitWeaponProperties(KFP);
}

function bool PickupQuery(Pawn Other, class<Inventory> ItemClass, Actor Pickup)
{
	return false;
}

function DiscardInventory( Pawn Other, optional controller Killer )
{
	if ( Other.InvManager != None )
	{
		ClearInventory(Other);
		Other.InvManager.DiscardInventory();
	}
}

function ClearInventory(Pawn Other)
{
	local Inventory inv;

	if ( Other.InvManager != None )
	{
		ForEach Other.InvManager.InventoryActors(class'Inventory', inv)
		{
			inv.Destroy();
			Other.Weapon = None;
			Other.InvManager.PendingWeapon = None; //try to clean destroy
		}
	}
}

function AddWeapon( KFPawn P , class<KFWeapon> weaponClass, optional bool atSpawn=false)
{
	local KFWeapon WP;
	
	if( P != none && weaponClass != none && P.InvManager != none )
	{
		if(atSpawn)
		{
			P.DefaultInventory.AddItem(weaponClass);
			return;
		}

		WP = Spawn(weaponClass, P);
		WP.GiveTo(P);
	}
}

function InitWeaponProperties(Pawn P, optional KFWeapon weap)
{
	local KFWeapon KFWP;
	
	if(weap == none && P != none)
		KFWP = KFWeapon(P.Weapon);
	else 
		KFWP = weap;

	if(KFWP == none)
		return;

	KFWP.bDropOnDeath = false;
	KFWP.bCanThrow = false;
	KFInventoryManager(P.InvManager).GiveWeaponAmmo(KFWP);
}

event AddDefaultInventory(Pawn P) //
{
	local GGPlayerReplicationInfo GGPRI;

	GGPRI = GGPlayerReplicationInfo(P.Controller.PlayerReplicationInfo);

	if(GGPRI == none)
		return;

	AddWeapon(KFPawn(P), LoadedGunsList[GetGGLevel(GGPRI)].weaponClass, true);
	P.AddDefaultInventory();
	InitWeaponProperties(P);
}

defaultproperties
{
	PlayerControllerClass=class'GGPlayerController'
	DefaultPawnClass=class'GGPawn_Human'
	PlayerReplicationInfoClass=class'GGPlayerReplicationInfo'
}
