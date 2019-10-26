class GGPawn_Human extends DMPawn_Human;

const DEF_HeadShotMult = 1.5f;

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