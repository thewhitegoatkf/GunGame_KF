class DMGFxHUD_WaveInfo extends KFGFxHUD_WaveInfo;

const DEF_WaveText = "Top Kills:";

var DMPlayerController DMPC;

function InitializeHUD()
{
    // waveText currentWave/maxWaves
    //    waitingForWaveStart
	SetString("waveText", DEF_WaveText);
    SetString("waitingForWaveStart", "----");
   	
    KFPC = KFPlayerController(GetPC());
    DMPC = DMPlayerController(KFPC);
}

function TickHud(float DeltaTime)
{
    if(KFGRI == none)
    {
        KFGRI = KFGameReplicationInfo(GetPC().WorldInfo.GRI);
    }
    else
    {
        DMPC.OnTick_WaveInfo(Self, DeltaTime);
    }
	if (ObjectiveContainer != none)
	{
		ObjectiveContainer.TickHud(DeltaTime);
	}
}


DefaultProperties
{
}