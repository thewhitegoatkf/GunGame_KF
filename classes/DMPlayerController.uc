class DMPlayerController extends KFPlayerController;

const DEF_LowHealthEffectUnderHP = 10; //50 is too high when theres no healing 

simulated function OnTick_WaveInfo(DMGFxHUD_WaveInfo waveinfo, float DeltaTime, DMGameReplicationInfo DMGRI)
{
	local int TimeRemaining;

	if(!DMGRI.bMatchHasBegun)
		return;

	if(DMGRI.IsWarmupRound())
	{
		TimeRemaining = DMGRI.WarmupTime - int(`TimeSince(DMGRI.WarmupStart));
		
		waveinfo.UpdateText(waveinfo.DEF_TextWarmupID, waveinfo.DEF_TextWarmup);
		waveinfo.UpdateTimeRemaining(TimeRemaining);
	}
	else
	{
		TickWaveInfo(waveinfo, DMGRI);
	}
}

simulated function TickWaveInfo(DMGFxHUD_WaveInfo waveinfo, DMGameReplicationInfo DMGRI)
{
	waveinfo.UpdateText(waveinfo.DEF_TextID, waveinfo.DEF_Text);
	waveinfo.UpdateScore(PlayerReplicationInfo.Kills);
	waveInfo.UpdateTopScore(DMGRI.GetTopScore());
	waveInfo.UpdateGoalScore(DMGRI.GoalScore);
	//waveinfo.SetString("waveText", waveinfo.DEF_WaveText);
	//waveinfo.SetString("waitingForWaveStart", String(PlayerReplicationInfo.Kills));
	//waveinfo.SetInt("currentWave" , DMGRI.GetTopScore()); 
	//waveinfo.SetInt("maxWaves" , DMGRI.GoalScore);
}

reliable client function ShowRespawnMessage()
{
	if(MyGFxHUD != none)
		MyGFxHUD.ShowNonCriticalMessage("Jump To Respawn");
}

reliable client function ShowPriorityMessage(string InPrimaryMessageString, string InSecondaryMessageString, int LifeTime)
{
	if(MyGFxHUD != none)
		MyGFxHUD.DisplayPriorityMessage(InPrimaryMessageString, InSecondaryMessageString, LifeTime, GMT_Null);
}

reliable server function RequestPlayerRespawn()
{
	if(Pawn == none && CanRestartPlayer()) //Add respawn timer
		WorldInfo.Game.RestartPlayer(self);
}

DefaultProperties
{
	PerkList.Empty()
	PerkList.Add((PerkClass=class'HumanPerk'))

	LowHealthThreshold=DEF_LowHealthEffectUnderHP;

	InputClass = class'DMPlayerInput'
}

