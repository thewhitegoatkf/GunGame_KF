class Deathmatch extends KFGameInfo
config(Deathmatch);

const DEF_GOALSCORE = 25; //Its not used in the default game 

var int LastTopScore;
var DMGameReplicationInfo MyDMGRI;
var KFPlayerController lastWinner;

var config int WarmupTime;
var config bool bEnableWarmup;

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
	MyDMGRI.WarmupTime = WarmupTime;
	SetGoalScore(GoalScore <= 0 ? DEF_GOALSCORE : GoalScore);
	UpdateGameSettings();
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

	if(bEnableWarmup && !MyDMGRI.IsWarmupRound())
		StartWarmupRound();
}

function StartWarmupRound()
{
	MyDMGRI.bWarmupRound = true;
	MyDMGRI.NotifyWarmupRoundStarted();
	SetTimer(WarmupTime, false, nameof(OnWarmupEnd));
}

function OnWarmupEnd()
{
	local DMPlayerController DMPC;

    foreach WorldInfo.AllControllers(class'DMPlayerController', DMPC)
	{
        if(DMPC.Pawn != none && KFPawn_Customization(DMPC.Pawn) == none)
        {
            DMPC.Pawn.Destroy();
            if(DMPC.PlayerReplicationInfo.bReadyToPlay)
            {
            	DMPC.ShowPriorityMessage("The Game Has Begun!", "Reach the highest score", 4);
            }
        }
	}

	ResetLevel();
	MyDMGRI.bWarmupRound = true; //ResetLevel shenanigans
	StartMatch();
	MyDMGRI.bWarmupRound = false;
}

function bool MajorityPlayersReady()
{
	if(bEnableWarmup)
		return true;
	return AnyPlayerReady();
}

function bool CheckAllPlayersReady()
{
	if(bEnableWarmup)
		return true;
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
	
	KFPC = KFPlayerController(Killer);
	KFPCK = KFPlayerController(KilledPlayer);
	KFPRI = KFPlayerReplicationInfo(Killer.PlayerReplicationInfo);

	if(KFPRI != none && KFPC != none && KFPC != KFPCK)
	{
		if(LastTopScore < KFPRI.Kills)
		{
			LastTopScore = KFPRI.Kills;
			MyDMGRI.TopScore = LastTopScore;
			UpdateGameSettings();
		}
		if(!MyDMGRI.bWarmupRound && KFPRI != none && KFPRI.Kills >= GoalScore)
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

function EndOfMatchWinner(KFPlayerController winnerController)
{
	local DMPlayerController KFPC;
	
	lastWinner = winnerController;
	//TODO:Add sounds for cooler effect
	foreach WorldInfo.AllControllers(class'DMPlayerController', KFPC)
	{
		if(KFPC == winnerController)
		{
			KFPC.ClientWonGame( WorldInfo.GetMapName(true), GameDifficulty, GameLength, IsMultiplayerGame());
			KFPC.ShowPriorityMessage("You won the game", "Congrats", 4);
		}
		else
		{
			KFPC.ClientGameOver( WorldInfo.GetMapName(true), GameDifficulty, GameLength, IsMultiplayerGame(), 0);
			if(winnerController != none)
				KFPC.ShowPriorityMessage(winnerController.PlayerReplicationInfo.PlayerName, "Won the game!", 4);
			else
				KFPC.ShowPriorityMessage("You have lost!", "it's a shame really", 4);
		}
	}
	GotoState('MatchEnded');
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

		SetTimer(4, false, nameof(SetWonGameCamera));
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

	SendMapOptionsAndOpenAARMenu();
	UpdateCurrentMapVoteTime( GetEndOfMatchTime(), true);
	WorldInfo.TWPushLogs();
}

static function SendMapOptionsAndOpenAARMenu()
{
	local WorldInfo WI;
	local KFPlayerController KFPC;
	local KFPlayerReplicationInfo KFPRI;
	local KFGameInfo KFGI;
	local int i;
	local KFGameReplicationInfo KFGRI;

	WI = Class'WorldInfo'.Static.GetWorldInfo();

	KFGI = KFGameInfo(WI.Game);
	KFGRI = KFGameReplicationInfo(WI.GRI);

	foreach WI.AllControllers(class'KFPlayerController', KFPC)
	{
		if(WI.NetMode == NM_StandAlone)
		{
			//set map list in vote collector
			if(KFGRI != none && KFGRI.VoteCollector != none)
			{
				class'KFGfxMenu_StartGame'.static.GetMapList(KFGRI.VoteCollector.MapList);
			}
		}
		else
		{
			KFPRI = KFPlayerReplicationInfo(KFPC.PlayerReplicationInfo);
			for (i = 0; i < KFGI.GameMapCycles[KFGI.ActiveMapCycle].Maps.length; i++)
		    {
				if(KFPRI != none)
				{
					KFPRI.RecieveAARMapOption(KFGI.GameMapCycles[KFGI.ActiveMapCycle].Maps[i]);
				}
			}
		}
		KFPC.ClientShowPostGameMenu();
	}
}

function float GetEndOfMatchTime()
{
	return MapVoteDuration;
}

function ProcessAwards()
{
	class'EphemeralMatchStats'.Static.ProcessPostGameStats();
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

	if (P.TeamIndex == Team)
		Rating += 15.f;
	
	if(Player == none)
		return Rating;

	if(Player.StartSpot != none && Player.StartSpot != P)
		Rating += 4.f;

	if ( CheckSpawnProximity( P, Player, Team ) )
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

function UpdateGameSettings()
{
	local name SessionName;
	local KFOnlineGameSettings KFGameSettings;
	local int NumHumanPlayers, i;
	local KFGameEngine KFEngine;

	if (WorldInfo.NetMode == NM_DedicatedServer || WorldInfo.NetMode == NM_ListenServer)
	{
		`REMOVEMESOON_ServerTakeoverLog("KFGameInfo_Survival.UpdateGameSettings 1 - GameInterface: "$GameInterface);
		if (GameInterface != None)
		{
			KFEngine = KFGameEngine(class'Engine'.static.GetEngine());

			SessionName = PlayerReplicationInfoClass.default.SessionName;

			if( PlayfabInter != none && PlayfabInter.GetGameSettings() != none )
			{
				KFGameSettings = KFOnlineGameSettings(PlayfabInter.GetGameSettings());
				KFGameSettings.bAvailableForTakeover = KFEngine.bAvailableForTakeover;
			}
			else
			{
				KFGameSettings = KFOnlineGameSettings(GameInterface.GetGameSettings(SessionName));
			}
			//Ensure bug-for-bug compatibility with KF1

			`REMOVEMESOON_ServerTakeoverLog("KFGameInfo_Survival.UpdateGameSettings 2 - KFGameSettings: "$KFGameSettings);

			if (KFGameSettings != None)
			{
				`REMOVEMESOON_ServerTakeoverLog("KFGameInfo_Survival.UpdateGameSettings 3 - KFGameSettings.bAvailableForTakeover: "$KFGameSettings.bAvailableForTakeover);

				KFGameSettings.Mode = GetGameModeNum();
				KFGameSettings.Difficulty = GameDifficulty;
				
				if(MyDMGRI != none)
				{
					if (!MyDMGRI.bMatchHasBegun || MyDMGRI.bWarmupRound)
					{
						KFGameSettings.bInProgress = false;
						KFGameSettings.CurrentWave = 0;
					}
					else
					{
						KFGameSettings.bInProgress = true;
						KFGameSettings.CurrentWave = MyDMGRI.TopScore;
					}

					KFGameSettings.NumWaves = MyDMGRI.GoalScore;
					MyDMGRI.bCustom = bIsCustomGame;
				}
				else
					KFGameSettings.NumWaves = GoalScore;

				KFGameSettings.OwningPlayerName = class'GameReplicationInfo'.default.ServerName;

				KFGameSettings.NumPublicConnections = MaxPlayersAllowed;
				KFGameSettings.bRequiresPassword = RequiresPassword();
				KFGameSettings.bCustom = bIsCustomGame;
				KFGameSettings.bUsesStats = !IsUnrankedGame();
				KFGameSettings.NumSpectators = NumSpectators;

				// Set the map name
				if( WorldInfo.IsConsoleDedicatedServer() )
				{
					KFGameSettings.MapName = WorldInfo.GetMapName(true);
					if( GameReplicationInfo != none )
					{
						for( i = 0; i < GameReplicationInfo.PRIArray.Length; i++ )
						{
							if( !GameReplicationInfo.PRIArray[i].bBot )
							{
								NumHumanPlayers++;
							}
						}
					}

					KFGameSettings.NumOpenPublicConnections = KFGameSettings.NumPublicConnections - NumHumanPlayers;
				}

				`REMOVEMESOON_ServerTakeoverLog("KFGameInfo_Survival.UpdateGameSettings 4 - PlayfabInter: "$PlayfabInter);
				if (PlayfabInter != none)
				{
					`REMOVEMESOON_ServerTakeoverLog("KFGameInfo_Survival.UpdateGameSettings 4.1 - IsRegisteredWithPlayfab: "$PlayfabInter.IsRegisteredWithPlayfab());
				}

				if( PlayfabInter != none && PlayfabInter.IsRegisteredWithPlayfab() )
				{
					PlayfabInter.ServerUpdateOnlineGame();
				}
				else
				{
					//Trigger re-broadcast of game settings
					GameInterface.UpdateOnlineGame(SessionName, KFGameSettings, true);
				}
			}
		}
	}
}

DefaultProperties
{
	PlayerControllerClass=class'DMPlayerController'
	GameReplicationInfoClass=class'DMGameReplicationInfo'
	PlayerReplicationInfoClass=class'DMPlayerReplicationInfo'
	DefaultPawnClass=class'DMPawn_Human'
	HUDType = class'DMGFxHudWrapper'

	bTeamGame=false
	bCanPerkAlwaysChange=false
	LastTopScore=0
	MaxPlayersAllowed=32
}