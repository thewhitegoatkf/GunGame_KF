class DMGFxHUD_WaveInfo extends KFGFxHUD_WaveInfo;

const DEF_WaveText = "Top Kills:";

function InitializeHUD()
{
    // waveText currentWave/maxWaves
    //    waitingForWaveStart
	SetString("waveText", DEF_WaveText);
    SetString("waitingForWaveStart", "----");
   	
    KFPC = KFPlayerController(GetPC());
}

function TickHud(float DeltaTime)
{
    if(KFGRI == none)
    {
        KFGRI = KFGameReplicationInfo(GetPC().WorldInfo.GRI);
    }
    else
    {
    	SetString("waitingForWaveStart", String(KFPC.PlayerReplicationInfo.Kills));//$"/"$KFGRI.GoalScore);
     	SetInt("currentWave" , DMGameReplicationInfo(KFGRI).GetTopScore()); 
   		SetInt("maxWaves" , KFGRI.GoalScore);
    }
	if (ObjectiveContainer != none)
	{
		ObjectiveContainer.TickHud(DeltaTime);
	}
}


DefaultProperties
{
}