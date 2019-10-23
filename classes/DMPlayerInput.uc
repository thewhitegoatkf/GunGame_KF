class DMPlayerInput extends KFPlayerInput;

exec function Jump()
{
	local DMPlayerController DMPC;

	Super.Jump();
	

	if(Pawn != none)
		return;
		
	DMPC = DMPlayerController(Outer);
	if(DMPC != none && CanRestartPlayer())
	{
		DMPC.RequestPlayerRespawn();
		if(KFGFxHudWrapper(DMPC.myHUD) != none)
			KFGFxHudWrapper(DMPC.myHUD).HudMovie.HudChatBox.ClearAndCloseChat(); //Fix input taken over after respawn by chat
	}

	
}