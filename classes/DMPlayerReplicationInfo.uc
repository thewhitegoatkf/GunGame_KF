class DMPlayerReplicationInfo extends KFPlayerReplicationInfo;

//Fixes resetting bReadyToPlay after ResetLevel called causing to StartHumans to fail (TW Bug ?)
function Reset()
{
	local bool bOldReadyToPlay;

	bOldReadyToPlay = bReadyToPlay;
	Super.Reset();
	bReadyToPlay = bOldReadyToPlay;
}