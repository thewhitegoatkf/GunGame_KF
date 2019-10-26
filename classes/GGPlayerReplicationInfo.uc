class GGPlayerReplicationInfo extends DMPlayerReplicationInfo;

var int GunLevel;

replication
{
	if(bNetDirty)
		GunLevel;
}

function SetGunLevel(int Level)
{
	GunLevel = Level;
	bNetDirty = true;
}

//used to save properties after logging out we want to save that incase the player rejoins later in the match
function PlayerReplicationInfo Duplicate()
{
	local GGPlayerReplicationInfo NewKFPRI;

	NewKFPRI = GGPlayerReplicationInfo(super.Duplicate());
	CopyProperties(NewKFPRI);
	return NewKFPRI;
}

function CopyProperties(PlayerReplicationInfo PRI)
{
	local GGPlayerReplicationInfo NewKFPRI;
	
	NewKFPRI = GGPlayerReplicationInfo(PRI);
	NewKFPRI.GunLevel = GunLevel;
	Super.CopyProperties(PRI);
}

function Reset()
{
	Super.Reset();
	GunLevel = 0;
}

DefaultProperties
{
	GunLevel=0
}

