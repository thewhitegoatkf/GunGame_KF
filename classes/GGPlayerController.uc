class GGPlayerController extends DMPlayerController;

simulated function TickWaveInfo(DMGFxHUD_WaveInfo waveinfo)
{
	waveinfo.SetString("waveText", "Top Gun Lvl:");
	waveinfo.SetString("waitingForWaveStart", String(GGPlayerReplicationInfo(PlayerReplicationInfo).GunLevel));
	waveinfo.SetInt("currentWave" , DMGRI.GetTopScore()); 
	waveinfo.SetInt("maxWaves" , DMGRI.GoalScore);
}

DefaultProperties
{
	
}