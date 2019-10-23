class GGPawn_Human extends KFPawn_Human;

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

function AdjustDamage(out int InDamage, out vector Momentum, Controller InstigatedBy, vector HitLocation, class<DamageType> DamageType, TraceHitInfo HitInfo, Actor DamageCauser)
{
	local int HitZoneIdx;
	HitZoneIdx = HitZones.Find('ZoneName', HitInfo.BoneName);
	Super.AdjustDamage(InDamage, Momentum, InstigatedBy, HitLocation, DamageType, HitInfo, DamageCauser);
	if(HitZoneIdx == HZI_HEAD)
		InDamage *= DEF_HeadShotMult;
}