--[[
    PandaDamage.luau by TheLastPanda77
    A simple, no-fuss Roblox damage module.
    Thank you for choosing PandaDamage! 
]]

local Players = game:GetService("Players")

export type DamageMultipliers = {
	Combo: number?, -- Multiplies the total damage by this amount (the factor can be reduced in the PandaDamage.CONFIG)
	DamageMultiplier: number?, -- Multiplies the total damage by this amount (this represents a "strength" boost for the *attacker*)
	DamageTakenMultiplier: number?, -- Multiplies the total damage by this amount (this is a "take extra damage" boost for the *target*)
	LifestealPercent: number?, -- The percent of damage the attacker deals that is healed back to them
	ThornsPercent: number?, -- See ThornsMode below for explanation; treat this number as "x"
}

type ThornsMode = "Attacker" | "Target"
-- When set to "Attacker", x% of damage the attacker deals is dealt back to them
-- When set to "Target", x% of damage the target takes is dealt back to the attacker

local PandaDamage = {}

PandaDamage.CONFIG = {
	OVERALL_DAMAGE_MULTIPLIER = 1, -- All damage is multiplied by this value no matter the attacker or target's multipliers
	THORNS_MODE = "Attacker" :: ThornsMode, -- "Attacker" or "Target"
	COMBO_FACTOR = 1, -- The factor by which the combo multiplies the damage. For example, if set to 1, a combo of 3 will deal 3x damage.
	DEFAULT_TIMEOUT = 5, -- Amount of time in seconds before the attacker no longer gets credit if the target dies
	OnKill = function(killer: Player, victim: Player)
		print(`[PandaDamage] {killer} killed {victim}`)
		--[[ You can either modify the behaviour here or replace the entire function in a seperate script by setting 
        PandaDamage.CONFIG.OnKill = function(killer: Player, victim: Player)
            -- your code here
        end]]
	end,
}

local resetThreads = {}
local humanoidConnections = {}

local function applyLifesteal(attacker: Player, dealtDamage: number, lifestealPercent: number)
	if not attacker or not dealtDamage then
		warn(`[PandaDamage] Invalid arguments: {attacker}, {dealtDamage}`)
		return
	end

	local attackerCharacter = attacker.Character
	if not attackerCharacter then
		warn(`[PandaDamage] Attacker has no character: {attacker}`)
		return
	end

	local attackerHumanoid = attackerCharacter:FindFirstChildOfClass("Humanoid")
	if not attackerHumanoid then
		warn(`[PandaDamage] Attacker has no humanoid: {attacker}`)
		return
	end

	if attackerHumanoid.Health <= 0 then
		return
	end

	if lifestealPercent > 0 then
		local lifestealAmount = dealtDamage * lifestealPercent
		local newHealth = attackerHumanoid.Health + lifestealAmount

		attackerHumanoid.Health = math.min(newHealth, attackerHumanoid.MaxHealth)
	end
end

local function applyThorns(attacker: Player, dealtDamage: number, damage: number, thornsPercent: number)
	if thornsPercent > 0 then
		local thornsMode = PandaDamage.CONFIG.THORNS_MODE

		local attackerCharacter = attacker.Character
		if not attackerCharacter then
			warn(`[PandaDamage] Attacker has no character: {attacker}`)
			return
		end

		local attackerHumanoid = attackerCharacter:FindFirstChildOfClass("Humanoid")
		if not attackerHumanoid then
			warn(`[PandaDamage] Attacker has no humanoid: {attacker}`)
			return
		end

		if thornsMode == "Attacker" then
			if attackerHumanoid.Health > 0 then
				local thornsAmount = dealtDamage * thornsPercent -- takes dealt damage, despite how much the target takes
				attackerHumanoid:TakeDamage(math.min(thornsAmount, attackerHumanoid.Health))
			end
		else
			if attackerHumanoid.Health > 0 then
				local thornsAmount = damage * thornsPercent -- takes final damage
				attackerHumanoid:TakeDamage(math.min(thornsAmount, attackerHumanoid.Health))
			end
		end
	end	
end

function PandaDamage.ApplyDamage(attacker: Player, target: Player, baseDamage: number, multipliers: DamageMultipliers)
	if not attacker or not target or not baseDamage or not multipliers or baseDamage <= 0 then
		warn(`[PandaDamage] Invalid arguments: {attacker}, {target}, {baseDamage}, {multipliers}`)
		return
	end

	local targetCharacter = target.Character
	if not targetCharacter then
		warn(`[PandaDamage] Target has no character: {target}`)
		return
	end

	local targetHumanoid = targetCharacter:FindFirstChildOfClass("Humanoid")
	if not targetHumanoid then
		warn(`[PandaDamage] Target has no humanoid: {target}`)
		return
	end

	local combo = multipliers.Combo or 1
	combo = combo * PandaDamage.CONFIG.COMBO_FACTOR
	local damageMultiplier = multipliers.DamageMultiplier or 1
	local damageTakenMultiplier = multipliers.DamageTakenMultiplier or 1
	local lifestealPercent = multipliers.LifestealPercent or 0
	local thornsPercent = multipliers.ThornsPercent or 0

	local dealtDamage = baseDamage * PandaDamage.CONFIG.OVERALL_DAMAGE_MULTIPLIER * combo * damageMultiplier -- Damage the attacker dealt
	local damage = dealtDamage * damageTakenMultiplier -- The final damage, can be more or less, that the target takes

	applyLifesteal(attacker, dealtDamage, lifestealPercent)
	applyThorns(attacker, dealtDamage, damage, thornsPercent)

	if targetHumanoid.Health > 0 then
		targetHumanoid:TakeDamage(damage)
		target:SetAttribute("LastAttacker", attacker.UserId)

		if humanoidConnections[target] then
			humanoidConnections[target]:Disconnect()
		end

		humanoidConnections[target] = targetHumanoid.Died:Connect(function()
			local lastAttacker = target:GetAttribute("LastAttacker")
			local killer = lastAttacker and Players:GetPlayerByUserId(lastAttacker) or target

			local success, err = pcall(function()
				PandaDamage.CONFIG.OnKill(killer, target)
			end)

			if not success then
				warn(`[PandaDamage] Error in OnKill function: {err}`)
			end

			humanoidConnections[target]:Disconnect()
			humanoidConnections[target] = nil -- This is necessary to avoid a Players.PlayerRemoving connection
		end)

		if resetThreads[target] then
			resetThreads[target]:Cancel()
		end

		resetThreads[target] = task.delay(PandaDamage.CONFIG.DEFAULT_TIMEOUT, function()
			target:SetAttribute("LastAttacker", nil)
			resetThreads[target] = nil
		end)
	end
end

return PandaDamage
