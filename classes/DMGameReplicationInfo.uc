class DMGameReplicationInfo extends KFGameReplicationInfo
config(Deathmatch);

var int TopScore;

var int WarmupTime;
var float WarmupStart;

var repnotify bool bWarmupRound;

replication
{
	if(bNetInitial)
		WarmupTime;

	if(bNetDirty)
		TopScore, bWarmupRound;
}

simulated event ReplicatedEvent(name VarName)
{
 	if ( VarName == nameof(bWarmupRound) )
	{
		if(bWarmupRound)
		{
			NotifyWarmupRoundStarted();
		}
	}
	else 
		Super.ReplicatedEvent(VarName);
}

simulated function NotifyWarmupRoundStarted()
{
	local DMPlayerController DMPC;

	WarmupStart = WorldInfo.TimeSeconds;
	if(WorldInfo.NetMode != NM_DedicatedServer)
	{
		DMPC = DMPlayerController(GetALocalPlayerController());
		DMPC.ShowPriorityMessage("WARMUP ROUND", "Kill each other", 4);
	}
}

simulated function bool IsWarmupRound()
{
	return bWarmupRound;
}

simulated function int GetWarmupTimeLeft()
{
	return WarmupTime;
}

simulated function int GetTopScore()
{
	return TopScore;
}

simulated function Reset()
{
	Super.Reset();
	TopScore = 0;
	WarmupTime = 0;
	WarmupStart = 0;
	bWarmupRound = false;
}

DefaultProperties
{
	bWarmupRound=false
	bTradersEnabled=false
	bHidePawnIcons=true
}