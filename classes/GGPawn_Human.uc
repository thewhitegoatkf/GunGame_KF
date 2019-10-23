class GGPawn_Human extends KFPawn_Human;

function AddDefaultInventory()
{
	Super(KFPawn).AddDefaultInventory();
}

function ThrowWeaponOnDeath()
{

}

simulated function bool CanThrowWeapon()
{
	return false;
}