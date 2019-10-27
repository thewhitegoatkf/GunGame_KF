class DMGFxHUD_WaveInfo extends KFGFxHUD_WaveInfo;


var int LastGoalScore;
var int LastScore;
var int LastTopScore;
var int LastTimeRemaining;
var int LastTextID;

const DEF_Text = "Top Kills:";
const DEF_TextWarmup = "WARMUP";

const DEF_TextID = 0;
const DEF_TextWarmupID = 1;

const DEF_CountdownSoundSec = 5;

var DMPlayerController DMPC;
var DMGameReplicationInfo DMGRI;

function InitializeHUD()
{
    // waveText currentWave/maxWaves
    //    waitingForWaveStart
	SetString("waveText", DEF_Text);
    SetString("waitingForWaveStart", "----");
   	
    DMPC = DMPlayerController(GetPC());
}

function TickHud(float DeltaTime)
{
    if(DMGRI == none)
    {
        DMGRI = DMGameReplicationInfo(GetPC().WorldInfo.GRI);
    }
    else
    {
        DMPC.OnTick_WaveInfo(Self, DeltaTime, DMGRI);
    }
}

function UpdateGoalScore(int GoalScore)
{
    if(GoalScore != LastGoalScore)
    {
        SetInt("maxWaves" , GoalScore);
        LastGoalScore = GoalScore;
    }
}

function UpdateScore(int Score)
{
    if(Score != LastScore)
    {
        SetString("waitingForWaveStart", String(Score));
        LastScore = Score;
    }
}

function UpdateTopScore(int TopScore)
{
    if(TopScore != LastTopScore)
    {
        SetInt("currentWave" , TopScore);
        LastTopScore = TopScore;
    }
}

function UpdateTimeRemaining(int TimeRemaining)
{
    if(TimeRemaining != LastTimeRemaining)
    {
        SetInt("remainingTraderTime" , TimeRemaining);
        LastTimeRemaining = TimeRemaining;
        if (LastTimeRemaining < DEF_CountdownSoundSec && LastTimeRemaining >= 0)
        {
            if (DMPC != none && DMPC.MyGFxHUD != none)
            {
                DMPC.MyGFxHUD.PlaySoundFromTheme('TraderTime_Countdown', 'UI');
            }
        }
    }
}

function UpdateText(int TextID, string text)
{
    if(TextID != LastTextID)//string compare would be more expansive with no benefit 
    {
        SetString("waveText", text);
        LastTextID = TextID;
    }
}

DefaultProperties
{
    LastGoalScore=-1
    LastScore=-1
    LastTopScore=-1
    LastTimeRemaining=-1
    LastTextID=-1
}