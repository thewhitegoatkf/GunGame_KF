class DMGFxMoviePlayer_HUD extends KFGFxMoviePlayer_HUD;

event bool WidgetInitialized(name WidgetName, name WidgetPath, GFxObject Widget)
{
	if(WidgetName == 'WaveInfoContainer')
	{
		if ( WaveInfoWidget == none )
        {
        	WaveInfoWidget = DMGFxHUD_WaveInfo(Widget);
            WaveInfoWidget.InitializeHUD(); 
            SetWidgetPathBinding( Widget, WidgetPath );
        }
	}
	else 
        return Super.WidgetInitialized(WidgetName, WidgetPath, Widget);
	return true;
}


function ShowKillMessage ( PlayerReplicationInfo PRI1, PlayerReplicationInfo PRI2, optional bool bDeathMessage=false, optional Object OptionalObject)
{
    local GFxObject DataObject;
    local bool bHumanDeath;
    local string KilledName, KillerName, KilledIconpath, KillerIconPath;
    local string KillerTextColor, KilledTextColor;
    local class<KFPawn_Monster> KFPM;
    local class<KFDamageType> KFDT;
    local class<KFWeaponDefinition> KFWD;

    if(KFPC == none)
    {
        return;
    }
    KFDT = class<KFDamageType>(OptionalObject);

    if(KFDT != none)
    	KFWD = KFDT.Default.WeaponDef;

    KFPM=class<KFPawn_Monster>(OptionalObject);

 if( KFGXHUDManager != none )
    {
        if(bDeathMessage)
        {
            if(KFPM != none)
            {
                KillerName=KFPM.static.GetLocalizedName();
                KillerTextColor=ZEDTeamTextColor;
                KillerIconpath="img://"$class'KFPerk_Monster'.static.GetPerkIconPath();
            }
            else if(PRI1 != none)
            {
            	KillerName=PRI1.PlayerName;
                KillerTextColor=ZEDTeamTextColor;
                KillerIconpath="img://"$KFPlayerReplicationInfo(PRI1).CurrentPerkClass.static.GetPerkIconPath();
            }
        }
        else
        {
            if(KFPM != none)
            {
                KilledName=KFPM.static.GetLocalizedName();
                bHumanDeath=false;
            }
            else if(PRI1 != none)
            {
                if(PRI1.GetTeamNum() == 255)
                {
                    KillerTextColor=ZEDTeamTextColor;
                    KillerIconpath="img://"$class'KFPerk_Monster'.static.GetPerkIconPath();
                }
                else
                {
                    KillerTextColor=HumanTeamTextColor;
                    KillerIconpath="img://"$KFPlayerReplicationInfo(PRI1).CurrentPerkClass.static.GetPerkIconPath();
                }
                KillerName=PRI1.PlayerName;
            }
        }

        if(PRI2 != none)
        {
            if(PRI2.GetTeamNum() == class'KFTeamInfo_Human'.default.TeamIndex)
            {
                bHumanDeath=true;
                KilledTextColor=HumanTeamTextColor;
            }
            else
            {
                KilledTextColor=ZEDTeamTextColor;
                bHumanDeath=false;
            }
            KilledName=PRI2.PlayerName;
            if(KFWD != none)
                KilledIconpath="img://"$KFWD.static.GetImagePath();
            else
                KillerIconpath="img://"$KFPlayerReplicationInfo(PRI2).CurrentPerkClass.static.GetPerkIconPath();
        }

        DataObject=CreateObject("Object");

        DataObject.SetBool("humanDeath", bHumanDeath);

        DataObject.SetString("killedName", KilledName);
        DataObject.SetString("killedTextColor", KilledTextColor);
        DataObject.SetString("killedIcon", KilledIconpath);

        DataObject.SetString("killerName", KillerName);
        DataObject.SetString("killerTextColor", KillerTextColor);
        DataObject.SetString("killerIcon", KillerIconpath);

        //temp remove when rest of design catches up
        DataObject.SetString("text", KillerName@KilledName);

        KFGXHUDManager.SetObject("newBark", DataObject);
    }
}

DefaultProperties
{
	WidgetBindings.Remove((WidgetName="WaveInfoContainer",WidgetClass=class'KFGFxHUD_WaveInfo'))
	WidgetBindings.Add((WidgetName="WaveInfoContainer",WidgetClass=class'DMGFxHUD_WaveInfo'))

	//WidgetBindings.Replace((WidgetClass=class'KFGFxHUD_WaveInfo'),(WidgetClass=class'DMGFxHUD_WaveInfo'))
}