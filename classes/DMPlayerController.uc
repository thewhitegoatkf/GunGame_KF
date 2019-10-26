class DMPlayerController extends KFPlayerController
DependsOn(DMGameReplicationInfo);

const DEF_LowHealthEffectUnderHP = 10; //50 is too high when theres no healing 

simulated function OnTick_WaveInfo(DMGFxHUD_WaveInfo waveinfo, float DeltaTime, KFGameReplicationInfo KFGRI)
{
	local DMGameReplicationInfo DMGRI;

	DMGRI = DMGameReplicationInfo(KFGRI);

	if(!DMGRI.bMatchHasBegun)
		return;

	if(DMGRI.IsWarmupRound())
	{
		waveinfo.SetString("waveText", "WARMUP");
		waveinfo.SetString("waitingForWaveStart", String(DMGRI.WarmupTime - int(`TimeSince(DMGRI.WarmupStart))));
		//waveinfo.SetInt("currentWave" , DMGRI.GetTopScore()); 
		//waveinfo.SetInt("maxWaves" , DMGRI.GoalScore);
	}
	else
	{
		TickWaveInfo(waveinfo, DMGRI);
	}
}

simulated function TickWaveInfo(DMGFxHUD_WaveInfo waveinfo, DMGameReplicationInfo DMGRI)
{
	waveinfo.SetString("waveText", waveinfo.DEF_WaveText);
	waveinfo.SetString("waitingForWaveStart", String(PlayerReplicationInfo.Kills));
	waveinfo.SetInt("currentWave" , DMGRI.GetTopScore()); 
	waveinfo.SetInt("maxWaves" , DMGRI.GoalScore);
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

