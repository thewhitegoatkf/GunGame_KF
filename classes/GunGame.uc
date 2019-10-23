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
	bDisablePickups=true;
	`log("GunGame game type initialized");
}

event PreBeginPlay()
{
	if(GunsList.length == 0)
		LoadDefaultsAndSave();

	PreLoadServerGuns();
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

function Killed(Controller Killer, Controller KilledPlayer, Pawn KilledPawn, class<DamageType> damageType)
{
	local GGPlayerController GGPC,GGPCK;
	local GGPlayerReplicationInfo GGPRI;
	local class<KFDamageType> KFDT;
    local class<KFWeaponDefinition> KFWD; 
    local sInterGunsList GGLIST;
	//
	GGPC = GGPlayerController(Killer);
	GGPCK = GGPlayerController(KilledPlayer);
	GGPRI = GGPlayerReplicationInfo(Killer.PlayerReplicationInfo);
	Super(KFGameInfo).Killed(Killer,KilledPlayer,KilledPawn,damageType);

	KFDT = class<KFDamageType>(damageType);
	if(KFDT != none)
		KFWD = KFDT.Default.WeaponDef;

	if(GGPRI != none && GGPC != none && GGPC != GGPCK && KFWD != none)
	{	//fixes dual weapons
		GGLIST = LoadedGunsList[GetGGLevel(GGPRI)];
		if((KFWD.Default.WeaponClassPath == GGLIST.classPath) || //check if killed by level weapon
		(GGLIST.weaponSingleClassPath != "" && GGLIST.weaponSingleClassPath == KFWD.Default.WeaponClassPath)) //check if it was 
		{
			`log("LevelUp: Player" @ GGPRI.PlayerName @ "To:" @ GGPRI.GunLevel);
			GGPRI.SetGunLevel(GGPRI.GunLevel+1);
			if(GGPRI.GunLevel > GoalScore)
			{
				EndOfMatchWinner(GGPC);
				return;
			}
			if(LastTopScore < GGPRI.GunLevel)
			{
				LastTopScore = GGPRI.GunLevel;
				MyDMGRI.TopScore = LastTopScore;
			}
			
			LevelUp(GGPC, GGPRI);
		}
	}
	
	if(GGPCK != none && GGPCK.CanRestartPlayer())
		GGPCK.ShowRespawnMessage();
}

function int GetGGLevel(GGPlayerReplicationInfo GGPRI)
{
	return Clamp(GGPRI.GunLevel, 0, LoadedGunsList.length);
}

function LevelUp(GGPlayerController GGPC, GGPlayerReplicationInfo GGPRI)
{
	local KFPawn KFP;
	KFP = KFPawn(GGPC.Pawn);

	if(KFP == none || !KFP.IsAliveAndWell())
		return;
	
	ClearInventory(KFP);
	//KFP.InvManager.DiscardInventory();
	AddWeapon(KFP, LoadedGunsList[GetGGLevel(GGPRI)].weaponClass);
	InitWeaponProperties(KFP);
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
