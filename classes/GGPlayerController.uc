class GGPlayerController extends DMPlayerController;

simulated function TickWaveInfo(DMGFxHUD_WaveInfo waveinfo, DMGameReplicationInfo DMGRI)
{
	waveinfo.SetString("waveText", "Top Lvl:");
	waveinfo.SetString("waitingForWaveStart", String(GGPlayerReplicationInfo(PlayerReplicationInfo).GunLevel));
	waveinfo.SetInt("currentWave" , DMGRI.GetTopScore()); 
	waveinfo.SetInt("maxWaves" , DMGRI.GoalScore);
}

DefaultProperties
{
	
}