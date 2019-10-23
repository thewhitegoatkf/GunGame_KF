class DMPlayerController extends KFPlayerController;

var int warmupCountdown;
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

	InputClass = class'DMPlayerInput'
}

