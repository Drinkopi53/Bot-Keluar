/*
	Based on v2.3.3

	enforce sniper rifle and shotgun, prevent vanilla AI switch to pistol/magnum/melee/chainsaw, only allow use secondary weapon when ammo run out(same as rifle).

	new settings:
		enforce_shotgun
		enforce_sniper_rifle
*/

// Tujuan Inovasi: Sistem Navigasi Bot yang Ditingkatkan (Enhanced Bot Navigation System - Dynamic Pathfinding)
// Meningkatkan algoritma pathfinding bot agar mereka dapat menemukan jalur yang lebih optimal, menghindari rintangan dinamis (misalnya, pintu yang tertutup, area yang diblokir oleh musuh), dan beradaptasi dengan perubahan lingkungan secara real-time, mengurangi insiden bot yang terjebak atau melakukan rute yang tidak efisien.
printl("enforce shotgun or sniper rifle");



// 0 = vanilla AI logic
	//shotgun: bot switch to secondary weapon when threats is outside about 800 range.
	//sniper rifle: bot switch to secondary weapon when threats is within about 300 range.

// pistol = 1, magnum = 2, melee = 4, chainsaw = 8
::Left4Bots.Settings.enforce_shotgun <- 15; // pistol + magnum + melee + chainsaw
::Left4Bots.Settings.enforce_sniper_rifle <- 15; // pistol + magnum + melee + chainsaw


// Returns the "WeaponType" for the weapon with the given id
::Left4Utils.GetWeaponTypeById <- function (weaponId)
{
	switch (weaponId)
	{
		case 2:
		case 7:
		case 33:
			return "smg";

		case 3:
		case 4:
		case 8:
		case 11:
			return "shotgun";

		case 5:
		case 9:
		case 26:
		case 34:
		case 37:
			return "rifle";

		case 6:
		case 10:
		case 35:
		case 36:
			return "sniper_rifle";

		case 21:
			return "grenade_launcher";

		case 1:
		case 32:
			return "pistol";

		case 19:
		case 101:
		case 102:
		case 103:
		case 104:
		case 105:
		case 106:
		case 107:
		case 108:
		case 109:
		case 110:
		case 111:
		case 112:
		case 113:
		case 114:
			return "melee";

		case 20:
			return "chainsaw";

		case 13:
		case 14:
		case 25:
			return "grenade";

		case 12:
		case 15:
		case 23:
		case 24:
			return "healing";

		case 30:
		case 31:
			return "upgradepack";

		case 16:
		case 17:
		case 18:
		case 27:
		case 28:
		case 29:
			return "carried_prop";

		default:
			return "unknow";
	}
}

::Left4Bots.EnforcePrimaryWeapon <- function(bot, ActiveWeapon)
{
	local canSwitch = true;
	if ((Settings.enforce_shotgun || Settings.enforce_sniper_rifle) && ActiveWeapon && !bot.IsIncapacitated())
	{
		local wp = Left4Utils.GetInventoryItemInSlot(bot, INV_SLOT_PRIMARY);
		local wp2nd = Left4Utils.GetInventoryItemInSlot(bot, INV_SLOT_SECONDARY);
		if (wp && wp2nd && Left4Utils.GetAmmoPercent(wp) > 0)
		{
			local type = Left4Utils.GetWeaponTypeById(Left4Utils.GetWeaponId(wp));
			if (type == "shotgun" || type == "sniper_rifle")
			{
				local type2nd = Left4Utils.GetWeaponTypeById(Left4Utils.GetWeaponId(wp2nd));
				local flag = type2nd == "pistol" ? (wp2nd.GetClassname() == "weapon_pistol_magnum" ? 2 : 1) :
							 type2nd == "melee" ? 4 :
							 type2nd == "chainsaw" ? 8 :
							 0;

				if (flag)
				{
					if ((Settings["enforce_" + type] & flag) == flag)
						canSwitch = false;

					if (!canSwitch && ActiveWeapon == wp2nd)
					{
						NetProps.SetPropEntity(wp2nd, "m_hOwner", bot);
						bot.SwitchToItem(wp.GetClassname());

						//if can not switch to primary weapon, at least we still have one, also fixed chainsaw smoking when pickup and switch at the same time
						return;
					}
				}
			}
		}
	}

	AllowSecondaryWeaponSwitch(bot, canSwitch);
}

::Left4Bots.AIFuncs.BotThink_Main <- function ()
{
	// https://github.com/smilz0/Left4Bots/issues/2
	if (++FuncI > 5)
		FuncI = 1;

	Origin = self.GetOrigin();
	CurTime = Time();
	ActiveWeapon = self.GetActiveWeapon();
	ActiveWeaponId = 0;
	ActiveWeaponSlot = -1;
	if (ActiveWeapon)
	{
		ActiveWeaponId = Left4Utils.GetWeaponId(ActiveWeapon);
		ActiveWeaponSlot = Left4Utils.GetWeaponSlotById(ActiveWeaponId);
	}

	// handle switch logic
	L4B.EnforcePrimaryWeapon(self, ActiveWeapon);

	// Basically, all this CarryItem stuff is because some carriable items despawn as prop_physics and respawn as weapon_* and viceversa when picking/dropping them
	// and also because the game's "dropped" event does not trigger every time
	if (CarryItem)
	{
		if (CarryItem != ActiveWeapon || !CarryItem.IsValid())
		{
			if (ActiveWeaponSlot == 5)
			{
				L4B.Logger.Debug("[AI]" + self.GetPlayerName() + " - Carry item changed: " + CarryItem + " -> " + ActiveWeapon);

				if (L4B.Settings.carry_debug)
					Say(self, "Carry item changed: " + CarryItem + " -> " + ActiveWeapon, false);

				local isCarryOrder = false;
				local ordersToUpdate = BotGetOrders(null, null, ActiveWeaponId);
				foreach (orderToUpdate in ordersToUpdate)
				{
					if (orderToUpdate.DestEnt.IsValid())
					{
						if (orderToUpdate.DestEnt == ActiveWeapon)
						{
							L4B.Logger.Debug("[AI]" + self.GetPlayerName() + " - Order's " + orderToUpdate.OrderType + " DestEnt has not changed: " + L4B.BotOrderToString(orderToUpdate));
							isCarryOrder = isCarryOrder || orderToUpdate.OrderType == "carry";
						}
						else
							L4B.Logger.Debug("[AI]" + self.GetPlayerName() + " - Unrelated order: " + L4B.BotOrderToString(orderToUpdate));
					}
					else
					{
						orderToUpdate.DestEnt = ActiveWeapon;
						L4B.Logger.Debug("[AI]" + self.GetPlayerName() + " - Order's " + orderToUpdate.OrderType + " DestEnt has been updated: " + L4B.BotOrderToString(orderToUpdate));
						isCarryOrder = isCarryOrder || orderToUpdate.OrderType == "carry";
					}
				}

				if (isCarryOrder)
					L4B.CarryItemStart(self);

				CarryItem = ActiveWeapon;
				CarryItemWeaponId = ActiveWeaponId;
			}
			else
			{
				L4B.Logger.Debug("[AI]" + self.GetPlayerName() + " - Carry item dropped: " + CarryItem);

				if (L4B.Settings.carry_debug)
					Say(self, "Carry item dropped: " + CarryItem, false);

				L4B.CarryItemStop(self);

				local ordersToUpdate = BotGetOrders(null, CarryItem, CarryItemWeaponId);
				foreach (orderToUpdate in ordersToUpdate)
				{
					if (orderToUpdate.OrderType == "scavenge" && orderToUpdate.DestPos)
					{
						orderToUpdate.DestPos = null;
						L4B.Logger.Debug("[AI]" + self.GetPlayerName() + " - Order's " + orderToUpdate.OrderType + " DestPos has been reset: " + L4B.BotOrderToString(orderToUpdate));
					}

					if (CarryItem.IsValid())
						L4B.Logger.Debug("[AI]" + self.GetPlayerName() + " - Order's " + orderToUpdate.OrderType + " dropped DestEnt is still valid: " + L4B.BotOrderToString(orderToUpdate));
					else
					{
						// Item dropped and no longer valid
						local newDestEnt = L4B.GetClosestCarriableByWeaponIdWhithin(Origin, CarryItemWeaponId, 350);
						if (newDestEnt)
						{
							orderToUpdate.DestEnt = newDestEnt;
							L4B.Logger.Debug("[AI]" + self.GetPlayerName() + " - Order's " + orderToUpdate.OrderType + " DestEnt has been updated: " + L4B.BotOrderToString(orderToUpdate));
						}
						else
						{
							L4B.Logger.Debug("[AI]" + self.GetPlayerName() + " - Order's " + orderToUpdate.OrderType + " DestEnt was lost. Cancelling the order: " + L4B.BotOrderToString(orderToUpdate));
							if (L4B.Settings.carry_debug)
								Say(self, orderToUpdate.OrderType + " item was lost", false);

							BotCancelOrder(orderToUpdate);
						}
					}
				}

				CarryItem = null;
				CarryItemWeaponId = 0;
			}
		}
	}
	else
	{
		if (ActiveWeaponSlot == 5)
		{
			CarryItem = ActiveWeapon;
			CarryItemWeaponId = ActiveWeaponId;

			L4B.Logger.Debug("[AI]" + self.GetPlayerName() + " - Carry item picked up: " + CarryItem);

			if (L4B.Settings.carry_debug)
				Say(self, "Carry item picked up: " + CarryItem, false);

			local isCarryOrder = false;
			local ordersToUpdate = BotGetOrders(null, null, CarryItemWeaponId);
			foreach (orderToUpdate in ordersToUpdate)
			{
				if (orderToUpdate.DestEnt.IsValid())
				{
					if (orderToUpdate.DestEnt == CarryItem)
					{
						L4B.Logger.Debug("[AI]" + self.GetPlayerName() + " - Order's " + orderToUpdate.OrderType + " item DestEnt has not changed: " + L4B.BotOrderToString(orderToUpdate));
						isCarryOrder = isCarryOrder || orderToUpdate.OrderType == "carry";
					}
					else
						L4B.Logger.Debug("[AI]" + self.GetPlayerName() + " - Unrelated order: " + L4B.BotOrderToString(orderToUpdate));
				}
				else
				{
					orderToUpdate.DestEnt = CarryItem;
					L4B.Logger.Debug("[AI]" + self.GetPlayerName() + " - Order's " + orderToUpdate.OrderType + " item DestEnt has been updated: " + L4B.BotOrderToString(orderToUpdate));
					isCarryOrder = isCarryOrder || orderToUpdate.OrderType == "carry";
				}
			}

			if (isCarryOrder)
				L4B.CarryItemStart(self);
		}
	}

	// Can't do anything at the moment
	if (L4B.SurvivorCantMove(self, Waiting))
	{
		if (!CanReset)
		{
			CanReset = true; // Now we can safely send RESET commands again

			L4B.Logger.Debug("Bot " + self.GetPlayerName() + " CanReset = true");

			// Delayed resets are executed as soon as we can reset again
			if (DelayedReset)
				BotReset(true);
		}
		if (AimType != AI_AIM_TYPE.None)
			BotUnSetAim();

		return L4B.Settings.bot_think_interval;
	}

	if (Airborne) // look at foot, simple way to fix the not fire bug
	{
		if (NetProps.GetPropEntity(self, "m_hGroundEntity"))
		{
			Left4Utils.BotLookAt(self, Origin);
			Airborne = false;
		}
		return L4B.Settings.bot_think_interval;
	}

	// Don't do anything if the bot is on a ladder or the mode hasn't started yet
	if (NetProps.GetPropInt(self, "movetype") == 9 /* MOVETYPE_LADDER */ || !L4B.ModeStarted)
		return L4B.Settings.bot_think_interval;

	//lxc exec here
	BotAim();

	// Don't do anything while frozen
	if ((NetProps.GetPropInt(self, "m_fFlags") & (1 << 5)))
	{
		// If the bot has FL_FROZEN flag set, CommandABot will fail even though it still returns true
		// Make sure to send at least one extra move command to the bot after the FL_FROZEN flag is unset
		if (MovePos)
			NeedMove = 2;

		return L4B.Settings.bot_think_interval;
	}

	if (L4B.Settings.fall_velocity_warp != 0 && self.GetVelocity().z <= (-L4B.Settings.fall_velocity_warp))
	{
		// https://github.com/smilz0/Left4Bots/issues/90
		local others = [];
		foreach (surv in L4B.GetOtherAliveSurvivors(UserId))
			others.append(surv);
		if (others.len() > 0)
		{
			local to = others[RandomInt(0, others.len() - 1)];
			if (to && to.IsValid())
			{
				self.SetVelocity(Vector(0,0,0));
				// need more step to avoid fall damage
				NetProps.SetPropInt(self, "m_fFlags", NetProps.GetPropInt(self, "m_fFlags") | 1); // 1 = FL_ONGROUND
				//lxc fix "warp" pos
				self.SetOrigin(to.IsHangingFromLedge() ? NetProps.GetPropVector(to, "m_hangStandPos") : to.GetOrigin());

				L4B.Logger.Info(self.GetPlayerName() + " has been teleported to " + to.GetPlayerName() + " while falling");

				return L4B.Settings.bot_think_interval;
			}
		}
	}

	if (L4B.Settings.stuck_detection)
		BotStuckMonitor();

	// HighPriority MOVEs are spit/charger dodging and such
	if (MovePos && MoveType == AI_MOVE_TYPE.HighPriority)
	{
		// Lets see if we reached our high priority destination...
		if ((Origin - MovePos).Length() <= L4B.Settings.move_end_radius)
		{
			// Yes, we did

			// No longer needed if we set sb_debug_apoproach_wait_time to something like 0.5 or even 0
			// BotReset();

			BotMoveReset();
			//MovePos = null;
			//MovePosReal = null;
			//MoveType = AI_MOVE_TYPE.None;
		}
		else if ((CurTime - MoveTime) >= MoveTimeout)
		{
			// No but the move timed out

			//BotReset();

			BotMoveReset();
			//MovePos = null;
			//MovePosReal = null;
			//MoveType = AI_MOVE_TYPE.None;
		}
		else
			BotMoveTo(MovePos); // No, keep moving
	}

	if (CurTime < HurryUntil) // TODO: Maybe we should also stop high priority moves
	{
		// "hurry" command was used
		if (FuncI == 5)
			BotThink_Misc(); // Still need to trigger car alarms
		return L4B.Settings.bot_think_interval;
	}

	if (L4B.Settings.close_saferoom_door_highres)
		BotThink_Door();

	switch (FuncI)
	{
		case 1:
		{
			//lxc avoid interrupt other order
			// in test, although bot are throwing a grenade, he also turn to pickup item, then throw the grenade at feet.
			if (AimType <= AI_AIM_TYPE.Shoot)
				BotThink_Pickup();
			break;
		}
		case 2:
		{
			BotThink_Defib(); // TODO: turn this into an order
			break;
		}
		case 3:
		{
			BotThink_Throw();
			break;
		}
		case 4:
		{
			BotThink_Orders();
			break;
		}
		case 5:
		{
			if (!L4B.Settings.close_saferoom_door_highres)
				BotThink_Door();

			BotThink_Misc();
			break;
		}
	}

	return L4B.Settings.bot_think_interval;
}

// Main bot think function for the extra L4D1 bots
::Left4Bots.AIFuncs.BotThink_Main_L4D1 <- function ()
{
	// https://github.com/smilz0/Left4Bots/issues/2
	if (++FuncI > 5)
		FuncI = 1;

	Origin = self.GetOrigin();
	CurTime = Time();
	ActiveWeapon = self.GetActiveWeapon();
	ActiveWeaponId = 0;
	ActiveWeaponSlot = -1;
	if (ActiveWeapon)
	{
		ActiveWeaponId = Left4Utils.GetWeaponId(ActiveWeapon);
		ActiveWeaponSlot = Left4Utils.GetWeaponSlotById(ActiveWeaponId);
	}

	// handle switch logic
	L4B.EnforcePrimaryWeapon(self, ActiveWeapon);

	// Can't do anything at the moment
	if (L4B.SurvivorCantMove(self, Waiting))
	{
		if (!CanReset)
		{
			CanReset = true; // Now we can safely send RESET commands again

			L4B.Logger.Debug("L4D1 Bot " + self.GetPlayerName() + " CanReset = true");

			// Delayed resets are executed as soon as we can reset again
			if (DelayedReset)
				BotReset(true);
		}
		if (AimType != AI_AIM_TYPE.None)
			BotUnSetAim();

		return L4B.Settings.bot_think_interval;
	}

	if (Airborne) // look at foot, simple way to fix the not fire bug
	{
		if (NetProps.GetPropEntity(self, "m_hGroundEntity"))
		{
			Left4Utils.BotLookAt(self, Origin);
			Airborne = false;
		}
		return L4B.Settings.bot_think_interval;
	}

	// Don't do anything if the bot is on a ladder or the mode hasn't started yet
	if (NetProps.GetPropInt(self, "movetype") == 9 /* MOVETYPE_LADDER */ || !L4B.ModeStarted)
		return L4B.Settings.bot_think_interval;

	//lxc exec here
	BotAim();

	// Don't do anything while frozen
	if ((NetProps.GetPropInt(self, "m_fFlags") & (1 << 5)))
	{
		// If the bot has FL_FROZEN flag set, CommandABot will fail even though it still returns true
		// Make sure to send at least one extra move command to the bot after the FL_FROZEN flag is unset
		if (MovePos)
			NeedMove = 2;

		return L4B.Settings.bot_think_interval;
	}

	//if (L4B.Settings.stuck_detection)
	//	BotStuckMonitor();

	switch (FuncI)
	{
		case 1:
		{
			//lxc avoid interrupt other order
			if (AimType <= AI_AIM_TYPE.Shoot)
				BotThink_Pickup();
			break;
		}
		case 3:
		{
			BotThink_Throw();
			break;
		}
		case 5:
		{
			BotManualAttack();
			break;
		}
	}

	return L4B.Settings.bot_think_interval;
}

