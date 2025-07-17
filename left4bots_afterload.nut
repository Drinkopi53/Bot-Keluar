'''/*
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

// Variabel global untuk menyimpan target Tank
::g_hTankTarget <- null;


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

// Fungsi untuk mendeteksi Tank yang aktif
::L4B_IsTankActive <- function()
{
	local tank = Entities.FindByClassname(null, "tank");
	if (tank && tank.IsValid())
	{
		g_hTankTarget = tank;
		return true;
	}

	g_hTankTarget = null;
	return false;
}

// Fungsi untuk mendapatkan jarak optimal berdasarkan senjata
::L4B_GetOptimalDistance <- function(hBot, hWeapon)
{
	local weaponType = Left4Utils.GetWeaponTypeById(Left4Utils.GetWeaponId(hWeapon));
	switch (weaponType)
	{
		case "shotgun":
			return { min = 200, max = 500 };
		case "sniper_rifle":
			return { min = 800, max = 1500 };
		default:
			return { min = 400, max = 1000 }; // Jarak default untuk senjata lain
	}
}

// Fungsi untuk mencari penutup dari Tank
::L4B_FindCover <- function(hBot, hTank)
{
    local botOrigin = hBot.GetOrigin();
    local tankOrigin = hTank.GetOrigin();
    local bestCover = null;
    local bestCoverScore = 0;

    // Cari objek di sekitar bot
    local ent = null;
    while (ent = Entities.FindInSphere(ent, botOrigin, 1000))
    {
        if (ent && ent.IsValid() && ent.IsSolid() && ent.GetClassname() != "player")
        {
            // Cek apakah objek bisa memblokir pandangan dari Tank
            local coverPos = ent.GetOrigin();
            local trace = {};
            TraceLine(trace, tankOrigin, botOrigin, MASK_SOLID_BRUSHONLY, hTank);
            if (trace.fraction < 1.0 && trace.pHit == ent)
            {
                // Beri skor pada penutup
                local score = 1.0 / (botOrigin - coverPos).Length(); // Lebih dekat lebih baik
                if (score > bestCoverScore)
                {
                    bestCoverScore = score;
                    bestCover = coverPos;
                }
            }
        }
    }
    return bestCover;
}

// Fungsi untuk melakukan pergerakan lateral
::L4B_PerformLateralMovement <- function(hBot, hTank)
{
    local botOrigin = hBot.GetOrigin();
    local tankOrigin = hTank.GetOrigin();

    local toTank = (tankOrigin - botOrigin).Norm();
    local right = toTank.Cross(Vector(0,0,1));

    local moveDir = (RandomInt(0, 1) == 0) ? right : -right;
    local movePos = botOrigin + (moveDir * 150);

    // Cek apakah posisi baru valid
    local nav = NavMesh.GetNearestNavArea(movePos);
    if (nav && nav.IsValid())
    {
        Left4Utils.BotCmdMove(self, movePos);
    }
}

// Fungsi untuk memeriksa apakah bot terjebak
::L4B_IsBotTrapped <- function(hBot)
{
    local nav = NavMesh.GetNearestNavArea(hBot.GetOrigin());
    if (nav && nav.IsValid())
    {
        if (nav.GetConnectionCount() <= 1) // Hanya satu atau tidak ada jalan keluar
        {
            return true;
        }
    }
    return false;
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

	// Deteksi Tank
	if (L4B_IsTankActive() && g_hTankTarget)
	{
		local tankOrigin = g_hTankTarget.GetOrigin();
		local tankVelocity = g_hTankTarget.GetVelocity();
		// Simpan posisi dan kecepatan tank untuk digunakan nanti
		self.GetScriptScope().lastTankOrigin <- tankOrigin;
		self.GetScriptScope().lastTankVelocity <- tankVelocity;

		// Logika Hindari Terjebak
		if (L4B_IsBotTrapped(self))
		{
			local escapePath = FindPath(NavMesh.GetNearestNavArea(self.GetOrigin()), NavMesh.GetNearestNavArea(g_hTankTarget.GetOrigin(), false));
			if (escapePath && escapePath.len() > 1)
			{
				Left4Utils.BotCmdMove(self, escapePath[1].GetCenter());
				return L4B.Settings.bot_think_interval;
			}
		}

		// Logika Penggunaan Penutup
		local coverPos = L4B_FindCover(self, g_hTankTarget);
		if (coverPos)
		{
			Left4Utils.BotCmdMove(self, coverPos);
			return L4B.Settings.bot_think_interval; // Prioritaskan mencari penutup
		}

		// Logika Pergerakan Lateral
		L4B_PerformLateralMovement(self, g_hTankTarget);

		// Logika Jarak Optimal
		local hWeapon = self.GetActiveWeapon();
		if (hWeapon)
		{
			local optimalDist = L4B_GetOptimalDistance(self, hWeapon);
			local currentDist = (self.GetOrigin() - tankOrigin).Length();

			if (currentDist < optimalDist.min)
			{
				// Terlalu dekat, mundur
				local awayVector = (self.GetOrigin() - tankOrigin).Norm();
				local movePos = self.GetOrigin() + (awayVector * 200);
				Left4Utils.BotCmdMove(self, movePos);
			}
			else if (currentDist > optimalDist.max)
			{
				// Terlalu jauh, maju
				local towardsVector = (tankOrigin - self.GetOrigin()).Norm();
				local movePos = self.GetOrigin() + (towardsVector * 200);
				Left4Utils.BotCmdMove(self, movePos);
			}
		}
	}

	// handle switch logic
	L4B.EnforcePrimaryWeapon(self, ActiveWeapon);

	// Panggil fungsi deteksi Tank
	L4B_IsTankActive();

	// Logika Posisi Bertahan Adaptif (jika Tank aktif)
	if (g_hTankTarget)
	{
		local botOrigin = self.GetOrigin();
		local distanceToTank = (botOrigin - g_vTankLastKnownPos).Length();
		local optimalDistance = L4B_GetOptimalDistance(self);

		if (distanceToTank < optimalDistance * 0.8) // Terlalu dekat
		{
			local moveAwayVector = (botOrigin - g_vTankLastKnownPos).Norm() * 200;
			local safePos = botOrigin + moveAwayVector;
			Left4Utils.BotCmdMove(self, safePos);
			printl("Bot " + self.GetPlayerName() + " bergerak mundur dari Tank.");
			return L4B.Settings.bot_think_interval; // Langsung proses frame berikutnya
		}
		else if (distanceToTank > optimalDistance * 1.2) // Terlalu jauh
		{
			// Coba bergerak lebih dekat, tapi tetap pertahankan garis tembak
			local targetPos = g_vTankLastKnownPos;
			Left4Utils.BotCmdMove(self, targetPos);
			printl("Bot " + self.GetPlayerName() + " bergerak maju mendekati Tank.");
		}

		// Cek apakah perlu mencari perlindungan
		local traceData = { start = botOrigin, end = g_vTankLastKnownPos, ignore = self };
		TraceLine(traceData);
		if (traceData.fraction == 1.0) // Tidak ada halangan, bot di area terbuka
		{
			local coverPos = L4B_FindCover(self, g_hTankTarget);
			if (coverPos)
			{
				Left4Utils.BotCmdMove(self, coverPos);
				printl("Bot " + self.GetPlayerName() + " mencari perlindungan dari Tank.");
				return L4B.Settings.bot_think_interval;
			}
		}

		// Lakukan pergerakan lateral secara acak untuk menghindari serangan
		if (RandomInt(0, 10) == 0) // 10% kemungkinan setiap think
		{
			L4B_PerformLateralMovement(self, g_hTankTarget);
			return L4B.Settings.bot_think_interval;
		}

		// Cek apakah bot terjebak
		if (L4B_IsBotTrapped(self))
		{
			printl("Bot " + self.GetPlayerName() + " terjebak, mencari jalan keluar.");
			// Cari area yang lebih terbuka yang jauh dari Tank
			local escapePos = g_vTankLastKnownPos + ((self.GetOrigin() - g_vTankLastKnownPos).Norm() * 1000);
			local startNav = NavMesh.GetNearestNavArea(self.GetOrigin());
			local endNav = NavMesh.GetNearestNavArea(escapePos);
			if (startNav && endNav)
			{
				local path = FindPath(startNav, endNav);
				if (path)
				{
					self.GetScriptScope().currentPath = path;
					self.GetScriptScope().pathIndex = 0;
					printl("Bot " + self.GetPlayerName() + " menemukan jalur evakuasi.");
					return L4B.Settings.bot_think_interval;
				}
			}
		}
	}

	// Dynamic Pathfinding
	if ("currentPath" in self.GetScriptScope() && self.GetScriptScope().currentPath)
	{
		local scope = self.GetScriptScope();
		local path = scope.currentPath;
		local index = scope.pathIndex;

		if (index < path.len())
		{
			local nextNav = path[index];
			local dest = nextNav.GetCenter();
			if ((Origin - dest).Length() < 50)
			{
				scope.pathIndex++;
			}
			else
			{
				Left4Utils.BotCmdMove(self, dest);
			}
			return L4B.Settings.bot_think_interval;
		}
		else
		{
			scope.currentPath = null;
			scope.pathIndex = 0;
		}
	}


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

	// Dynamic Pathfinding
	DetectDynamicObstacles(self);

	return L4B.Settings.bot_think_interval;
}

// Fungsi untuk mendeteksi rintangan dinamis
::DetectDynamicObstacles <- function(bot)
{
	local botOrigin = bot.GetOrigin();
	local velocity = bot.GetVelocity();
	local forward;
	if (velocity.LengthSqr() > 0)
	{
		forward = Vector(velocity.x, velocity.y, velocity.z);
		forward.Norm();
	}
	else
	{
		local angles = bot.EyeAngles();
		forward = AngleToForwardVector(angles);
	}
	local checkPos = botOrigin + (forward * 100); // Periksa 100 unit di depan bot

	// Periksa pintu
	local door = Entities.FindByClassnameWithin(null, "prop_door_rotating", checkPos, 150);
	if (door && door.IsValid())
	{
		local doorState = NetProps.GetPropInt(door, "m_bOpen");
		if (doorState == 0) // Pintu tertutup
		{
			printl("Bot " + bot.GetPlayerName() + " mendeteksi pintu tertutup.");
			try
			{
				local startNav = NavMesh.GetNearestNavArea(botOrigin);
				if (startNav && bot.GetScriptScope().MovePos)
				{
					local endNav = NavMesh.GetNearestNavArea(bot.GetScriptScope().MovePos);
					if (endNav)
					{
						local path = FindPath(startNav, endNav);
						if (path)
						{
							bot.GetScriptScope().currentPath = path;
							bot.GetScriptScope().pathIndex = 0;
							return;
						}
					}
				}
			}
			catch (ex)
			{
				printl("Error di DetectDynamicObstacles (pintu): " + ex);
			}
		}
	}

	// Periksa gerombolan musuh
	local commonInfected = 0;
	local ent = null;
	while(ent = Entities.FindByClassnameWithin(ent, "infected", checkPos, 200))
	{
		if (ent)
			commonInfected++;
	}

	if (commonInfected > 10) // Jika ada lebih dari 10 musuh
	{
		printl("Bot " + bot.GetPlayerName() + " mendeteksi gerombolan musuh.");
		try
		{
			local startNav = NavMesh.GetNearestNavArea(botOrigin);
			if (startNav && bot.GetScriptScope().MovePos)
			{
				local endNav = NavMesh.GetNearestNavArea(bot.GetScriptScope().MovePos);
				if (endNav)
				{
					local path = FindPath(startNav, endNav);
					if (path)
					{
						bot.GetScriptScope().currentPath = path;
						bot.GetScriptScope().pathIndex = 0;
						return;
					}
				}
			}
		}
		catch (ex)
		{
			printl("Error di DetectDynamicObstacles (gerombolan): " + ex);
		}
	}
}

// Simpan fungsi AddBotThink yang asli
if (!("AddBotThink_orig" in ::Left4Bots))
	::Left4Bots.AddBotThink_orig <- ::Left4Bots.AddBotThink;

// Timpa AddBotThink untuk menambahkan variabel pathfinding
::Left4Bots.AddBotThink <- function(bot)
{
	// Panggil fungsi asli terlebih dahulu
	::Left4Bots.AddBotThink_orig(bot);

	// Tambahkan variabel pathfinding ke scope bot
	local scope = bot.GetScriptScope();
	if (!("currentPath" in scope))
	{
		scope.currentPath <- null;
		scope.pathIndex <- 0;
	}
}

// Fungsi untuk mengonversi sudut yaw ke vektor maju
::AngleToForwardVector <- function(angles)
{
	local pitch = angles.x * (PI / 180.0);
	local yaw = angles.y * (PI / 180.0);
	local x = cos(yaw) * cos(pitch);
	local y = sin(yaw) * cos(pitch);
	local z = -sin(pitch);
	return Vector(x, y, z);
}

// Fungsi untuk menghitung jarak heuristik (Manhattan distance)
::Heuristic <- function(a, b)
{
	return abs(a.x - b.x) + abs(a.y - b.y);
}

// Implementasi algoritma A*
::FindPath <- function(startNav, endNav)
{
	local openSet = [startNav];
	local cameFrom = {};
	local gScore = {};
	gScore[startNav] <- 0;

	local fScore = {};
	fScore[startNav] <- Heuristic(startNav.GetCenter(), endNav.GetCenter());

	while (openSet.len() > 0)
	{
		local current = null;
		local lowestFScore = 999999;
		foreach (nav in openSet)
		{
			if (fScore[nav] < lowestFScore)
			{
				lowestFScore = fScore[nav];
				current = nav;
			}
		}

		if (current == endNav)
		{
			// Path found, reconstruct
			local path = [current];
			while (current in cameFrom)
			{
				current = cameFrom[current];
				path.insert(0, current);
			}
			return path;
		}

		openSet.remove(openSet.find(current));

		for (local i = 0; i < current.GetConnectionCount(); i++)
		{
			local neighbor = current.GetConnection(i);
			if (!neighbor.IsValid()) continue;

			local tentativeGScore = gScore[current] + (current.GetCenter() - neighbor.GetCenter()).Length();
			if (!(neighbor in gScore) || tentativeGScore < gScore[neighbor])
			{
				cameFrom[neighbor] <- current;
				gScore[neighbor] <- tentativeGScore;
				fScore[neighbor] <- gScore[neighbor] + Heuristic(neighbor.GetCenter(), endNav.GetCenter());
				if (openSet.find(neighbor) == null)
				{
					openSet.append(neighbor);
				}
			}
		}
	}

	// No path found
	return null;
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
'''