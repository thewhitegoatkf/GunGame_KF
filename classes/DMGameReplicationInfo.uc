class DMGameReplicationInfo extends KFGameReplicationInfo
config(Deathmatch);

var int TopScore;
replication
{
	if(bNetDirty)
		TopScore;
}

simulated function int GetTopScore()
{
	return TopScore;
}

DefaultProperties
{
	 bTradersEnabled=false
	 bHidePawnIcons=true
}