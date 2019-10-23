class DMGFxHudWrapper extends KFGFxHudWrapper;

//disables displaying any info on the enemy

simulated function bool DrawFriendlyHumanPlayerInfo( KFPawn_Human KFPH )
{
	return true;
}

simulated function bool DrawScriptedPawnInfo(KFPawn_Scripted KFPS, float NormalizedAngle, bool bRendered)
{
	return false;
}

simulated function DrawPerkIcons(KFPawn_Human KFPH, float PerkIconSize, float PerkIconPosX, float PerkIconPosY, float SupplyIconPosX, float SupplyIconPosY, bool bDropShadow)
{

}

function CheckAndDrawRemainingZedIcons()
{

}

defaultproperties
{
	HUDClass=class'DMGFxMoviePlayer_HUD'
}