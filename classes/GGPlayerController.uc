class GGPlayerController extends DMPlayerController;

simulated function TickWaveInfo(DMGFxHUD_WaveInfo waveinfo, DMGameReplicationInfo DMGRI)
{
	waveinfo.UpdateText(3,  "Top LVL:");
	waveinfo.UpdateScore(GGPlayerReplicationInfo(PlayerReplicationInfo).GunLevel);
	waveInfo.UpdateTopScore(DMGRI.GetTopScore());
	waveInfo.UpdateGoalScore(DMGRI.GoalScore);

	/*waveinfo.SetString("waveText", "Top Lvl:");
	waveinfo.SetString("waitingForWaveStart", String(GGPlayerReplicationInfo(PlayerReplicationInfo).GunLevel));
	waveinfo.SetInt("currentWave" , DMGRI.GetTopScore()); 
	waveinfo.SetInt("maxWaves" , DMGRI.GoalScore);*/
}

DefaultProperties
{
	
}