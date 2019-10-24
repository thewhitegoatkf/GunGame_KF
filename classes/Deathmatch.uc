class Deathmatch extends KFGameInfo
config(Deathmatch);

const DEF_GOALSCORE = 25; //Its not used in the default game 

var int LastTopScore;
var DMGameReplicationInfo MyDMGRI;
var KFPlayerController lastWinner;

var float warmupTime;
var float timeLeftForWarmup;
var bool bWarmupRound;

event InitGame( string Options, out string ErrorMessage )
{
	Super.InitGame( Options, ErrorMessage );
	`log("Deathmatch initialized");
}

event PreBeginPlay()
{
	Super.PreBeginPlay();
	ReadyUpDelay = 20;

	MyDMGRI = DMGameReplicationInfo(WorldInfo.GRI);
	SetGoalScore(GoalScore <= 0 ? DEF_GOALSCORE : GoalScore);
}

event PostBeginPlay()
{
	Super.PostBeginPlay();
	SaveConfig();
}

function StartMatch()
{
	lastWinner = none;
	LastTopScore = 0;
	Super.StartMatch();
	ResetAllPickups();
}

function bool MajorityPlayersReady()
{
	return AnyPlayerReady();
}

function bool CheckAllPlayersReady()
{
	return NumPlayers >= MaxPlayersAllowed*0.25 ? Super.CheckAllPlayersReady() : false;
}

//Fixes calling broadcast with no damagetype for human kill
function BroadcastDeathMessage(Controller Killer, Controller Other, class<DamageType> damageType)
{
	if( Killer != none && Killer != Other)
	{
		BroadcastLocalized(self, class'KFLocalMessage_Game', KMT_Killed, Killer.PlayerReplicationInfo, Other.PlayerReplicationInfo, damageType );
	}
	else
		Super.BroadcastDeathMessage(Killer, Other, damageType);
}

function Killed(Controller Killer, Controller KilledPlayer, Pawn KilledPawn, class<DamageType> damageType)
{
	local KFPlayerController KFPC,KFPCK;
	local KFPlayerReplicationInfo KFPRI;
	local DMPlayerController DMPCK;
	Super.Killed(Killer,KilledPlayer,KilledPawn,damageType);
	//
	KFPC = KFPlayerController(Killer);
	KFPCK = KFPlayerController(KilledPlayer);
	KFPRI = KFPlayerReplicationInfo(Killer.PlayerReplicationInfo);

	if(KFPRI != none && KFPC != none && KFPC != KFPCK)
	{
		if(LastTopScore < KFPRI.Kills)
		{
			LastTopScore = KFPRI.Kills;
			MyDMGRI.TopScore = LastTopScore;
		}
		if(KFPRI != none && KFPRI.Kills >= GoalScore)
		{
			EndOfMatchWinner(KFPC);
		}
	}
	
	if(KFPCK != none && KFPCK.CanRestartPlayer())
	{
		DMPCK = DMPlayerController(KFPCK);
		if(DMPCK != none )
		{
			DMPCK.ShowRespawnMessage();
		}
	}
}

function SetGoalScore(int Score)
{
	GoalScore = Score;
	if(MyDMGRI != none)
		MyDMGRI.GoalScore = GoalScore;
}

// function CheckWaveEnd( optional bool bForceWaveEnd = false )
// {

// }

static function bool GametypeChecksDifficulty()
{
    return false;
}

static function bool GametypeChecksWaveLength()
{
    return false;
}

static function bool GetShouldShowLength()
{
	return false;
}

function CheckZedTimeOnKill(Controller Killer, Controller KilledPlayer, Pawn KilledPawn, class<DamageType> DamageType)
{

}

function EndOfMatchWinner(KFPlayerController winnerController)
{
	local DMPlayerController KFPC;
	lastWinner = winnerController;
	//`AnalyticsLog(("match_end", None, "#"$WaveNum, "#"$(bVictory ? "1" : "0"), "#"$GameConductor.ZedVisibleAverageLifespan));
	SetTimer(4, false, nameof(SetWonGameCamera));

	foreach WorldInfo.AllControllers(class'DMPlayerController', KFPC)
	{
		if(KFPC == winnerController)
		{
			KFPC.ClientWonGame( WorldInfo.GetMapName(true), GameDifficulty, GameLength, IsMultiplayerGame() );
			KFPC.ShowPriorityMessage("You won the game", "Congrats", 4);
			//BroadcastLocalizedToController(KFPC, class'KFLocalMessage_Priority', GMT_MatchWon);
		}
		else
		{
			KFPC.ClientGameOver( WorldInfo.GetMapName(true), GameDifficulty, GameLength, IsMultiplayerGame(), 0 );
			if(winnerController != none)
				KFPC.ShowPriorityMessage(winnerController.PlayerReplicationInfo.PlayerName, "Won the game!", 4);
			else
				KFPC.ShowPriorityMessage("You have lost!", "it's a shame really", 4);
			//BroadcastLocalizedToController(KFPC, class'KFLocalMessage_Priority', GMT_MatchLost);
		}
	}
	//SetZedsToVictoryState();
	GotoState('MatchEnded');
}

function SetWonGameCamera()
{
	local KFPlayerController KFPC;

	foreach WorldInfo.AllControllers( class'KFPlayerController', KFPC )
	{
		KFPC.ServerCamera( 'ThirdPerson' );
		if(lastWinner != none && lastWinner.Pawn != none && KFPC != lastWinner)
			KFPC.ClientSetViewTarget(lastWinner.Pawn);
	}
}

/*********************************************************************************************
 * state MatchEnded
 *********************************************************************************************/

 State MatchEnded
 {
 	function BeginState( Name PreviousStateName )
	{
		if (WorldInfo.NetMode == NM_DedicatedServer)
		{
			`REMOVEMESOON_ZombieServerLog("KFGameInfo_Survival:MatchEnded.BeginState - PreviousStateName: "$PreviousStateName);
		}

		`log("KFGameInfo_Survival - MatchEnded.BeginState - AARDisplayDelay:" @ 15);

		MyKFGRI.EndGame();
		MyKFGRI.bWaitingForAAR = true; //@HSL - JRO - 6/15/2016 - Make sure we're still at full speed before the end of game menu shows up

		if ( AllowBalanceLogging() )
		{
			LogPlayersKillCount();
		}

		SetTimer(1.f, false, nameof(ProcessAwards));
		SetTimer(15, false, nameof(ShowPostGameMenu));
	}

	event Timer()
	{
		if (WorldInfo.NetMode == NM_DedicatedServer)
		{
			`REMOVEMESOON_ZombieServerLog("KFGameInfo_Survival:MatchEnded.Timer - NumPlayers: "$NumPlayers);
		}

		global.Timer();
		if (NumPlayers == 0)
		{
			RestartGame();
		}
	}
 }

function EndOfMatch(bool bVictory)
{
	local KFPlayerController KFPC;

	if (WorldInfo.NetMode == NM_DedicatedServer)
	{
		`REMOVEMESOON_ZombieServerLog("KFGameInfo_Survival.EndOfMatch - bVictory: "$bVictory);
	}

	`AnalyticsLog(("match_end", None, "#"$0, "#"$(bVictory ? "1" : "0"), "#"$GameConductor.ZedVisibleAverageLifespan));

	if(bVictory)
	{
		SetTimer(4, false, nameof(SetWonGameCamera));

		foreach WorldInfo.AllControllers(class'KFPlayerController', KFPC)
		{
			KFPC.ClientWonGame( WorldInfo.GetMapName( true ), GameDifficulty, GameLength,	IsMultiplayerGame() );
		}

		BroadcastLocalizedMessage(class'KFLocalMessage_Priority', GMT_MatchWon);
	}
	else
	{
		BroadcastLocalizedMessage(class'KFLocalMessage_Priority', GMT_MatchLost);
	}

    foreach WorldInfo.AllControllers(class'KFPlayerController', KFPC)
	{
		KFPC.ClientGameOver( WorldInfo.GetMapName(true), GameDifficulty, GameLength, IsMultiplayerGame(), 0 );
	}

	GotoState('MatchEnded');
}

//Get Top voted map
function string GetNextMap()
{
	local KFGameReplicationInfo KFGRI;
	local int NextMapIndex;

	KFGRI = KFGameReplicationInfo(WorldInfo.GRI);
	if( KFGRI != none )
	{
		NextMapIndex = KFGRI.VoteCollector.GetNextMap();
	}

	if( NextMapIndex != INDEX_NONE )
	{
		if(WorldInfo.NetMode == NM_Standalone)
		{
			return KFGRI.VoteCollector.Maplist[NextMapIndex];
		}
		else
		{
			return GameMapCycles[ActiveMapCycle].Maps[NextMapIndex];
		}

	}

	return super.GetNextMap();
}

function ShowPostGameMenu()
{
	local KFGameReplicationInfo KFGRI;

	`log("KFGameInfo_Survival - ShowPostGameMenu");

	MyKFGRI.bWaitingForAAR = false; //@HSL - JRO - 6/15/2016 - Make sure we're still at full speed before the end of game menu shows up

	bEnableDeadToVOIP=true; //Being dead at this point is irrelevant.  Allow players to talk about AAR -ZG
	KFGRI = KFGameReplicationInfo(WorldInfo.GRI);

	if(KFGRI != none)
	{
		KFGRI.OnOpenAfterActionReport( GetEndOfMatchTime() );
	}

	class'EphemeralMatchStats'.Static.SendMapOptionsAndOpenAARMenu();

	UpdateCurrentMapVoteTime( GetEndOfMatchTime(), true);

	WorldInfo.TWPushLogs();
}

function float GetEndOfMatchTime()
{
	return MapVoteDuration;
}

function ProcessAwards()
{
	class'EphemeralMatchStats'.Static.ProcessPostGameStats();
}

function UpdateCurrentMapVoteTime(byte NewTime, optional bool bStartTime)
{
	if(WorldInfo.GRI.RemainingTime > NewTime || bStartTime)
	{
		ClearTimer(nameof(RestartGame));
		SetTimer(NewTime, false, nameof(TryRestartGame));
		WorldInfo.GRI.RemainingMinute = NewTime;
		WorldInfo.GRI.RemainingTime  = NewTime;
	}

	//in the case that the server has a 0 for the time we still want to be able to trigger a server travel.
	if(NewTime <= 0 || WorldInfo.GRI.RemainingTime <= 0)
	{
		TryRestartGame();
	}
}

function TryRestartGame()
{
	RestartGame();
}

function BroadcastLocalizedToController( PlayerController P, class<LocalMessage> Message, optional int Switch, optional PlayerReplicationInfo RelatedPRI_1, optional PlayerReplicationInfo RelatedPRI_2, optional Object OptionalObject )
{
	BroadcastHandler.BroadcastLocalized(Self, P, Message, Switch, RelatedPRI_1, RelatedPRI_2, OptionalObject);
}

//** Returns false if this is near another player or in-use spawn point 
static function bool CheckSpawnProximity( NavigationPoint P, Controller Player, byte TeamNum, optional bool bCustomizationPoint )
{
	local PlayerController PC;
	local KFPawn_Customization CPawn;
	local WorldInfo WI;
	local vector  ViewLocation;
	local rotator ViewRotation;

	WI = class'WorldInfo'.static.GetWorldInfo();
	foreach WI.AllControllers( class'PlayerController', PC ) //Controller for AI
	{

		if( PC == Player )
		{
			continue;
		}

		//choose a unique spawn for each player
		if( IsInitialSpawnPointSelection(WI) && !bCustomizationPoint )
		{
			if ( PC.StartSpot == P && PC.GetTeamNum() == TeamNum )
			{
				return false;
			}
		}
		// During gameplay, or using customization starts, ignore StartSpot and use distance
		else if( PC.Pawn != None && !PC.Pawn.bHidden )
		{
			if( bCustomizationPoint )
			{
				// invisible customization pawns are okay
				CPawn = KFPawn_Customization(PC.Pawn);
				if( CPawn != None && CPawn.bServerHidden )
				{
					continue;
				}
			}
			//`log("Spawn Distance:"@VSizeSq(PC.Pawn.Location - P.Location)@"Sqared Colission:"@Square(2.1 * PC.Pawn.GetCollisionRadius()));
			
			if( VSizeSq(PC.Pawn.Location - P.Location) < Square(4 * PC.Pawn.GetCollisionRadius()) )
			 	return false;

			PC.GetPlayerViewPoint(ViewLocation, ViewRotation);
			
			if( PC.Pawn.FastTrace(ViewLocation, P.Location,, true ) )
				return false;
		}
	}
	return true;
}

function bool ShouldSpawnAtStartSpot(Controller Player)
{
	return false;
}

/** Returns a low rating if other players are nearby (spawn will fail) */
function float RatePlayerStart(PlayerStart P, byte Team, Controller Player) //LOOPED FOREACH NAVPOINT
{
	local float Rating;

	//Rating = Super(KFGameInfo).RatePlayerStart(P, Team, Player);

	if (P.TeamIndex == Team)
		Rating += 15.f;
	
	// If (P.bEnabled) 
	// 	Rating += 4.f;
	if(Player.StartSpot != none && Player.StartSpot != P)
		Rating += 4.f;

	if ( Player.StartSpot != P && CheckSpawnProximity( P, Player, Team ) )
	{
		 Rating += 10.f; // Higher than disabled, but lower than default
	}
	return Rating;
}


/** returns whether the given Controller StartSpot property should be used as the spawn location for its Pawn */

function byte IsMultiplayerGame()
{
	return (WorldInfo.NetMode != NM_Standalone && GetNumPlayers()  > 1) ? 1 : 0;
}


DefaultProperties
{
	PlayerControllerClass=class'DMPlayerController'
	GameReplicationInfoClass=class'DMGameReplicationInfo'
	HUDType = class'DMGFxHudWrapper'

	//bWaitingToStartMatch=false
	//bDelayedStart=false

	bTeamGame=false
	bCanPerkAlwaysChange=false
	LastTopScore=0
	MaxPlayersAllowed=32
	//warmupTime=20.f
	//bWarmupRound=false
	//GameName = "Deathmatch"
}

// BUG:Wave Top kills doesn't update in on online game
// TODO:Match end stats of DM
// TODO:Respawn HUD time to show up
// TODO:Human perk add icon
// TODO:Fix Human perk SkillObject none issues
