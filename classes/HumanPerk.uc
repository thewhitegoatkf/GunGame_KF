class HumanPerk extends KFPerk
config(Deathmatch);

simulated event PreBeginPlay()
{
	PerkSkills.Remove(0, PerkSkills.length);
  	Super.PreBeginPlay();
}

DefaultProperties
{
	PerkSkills.Empty()
}

