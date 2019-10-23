class DMPlayerInput extends KFPlayerInput;

exec function Jump()
{
	local DMPlayerController DMPC;
	DMPC = DMPlayerController(Outer);

	if(Pawn == none && DMPC != none && CanRestartPlayer())
	{
		DMPC.RequestPlayerRespawn();
		if(KFGFxHudWrapper(DMPC.myHUD) != none)
			KFGFxHudWrapper(DMPC.myHUD).HudMovie.HudChatBox.ClearAndCloseChat(); //Fix input taken over after respawn by chat
	}

	Super.Jump();
}