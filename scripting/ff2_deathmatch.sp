#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>
#include <tf2items>
#include <morecolors>
#include <freak_fortress_2>

// 아나운서의 음성은 FF2에서 이미 다운로드 테이블에 올리고, 캐시해둠.

bool enabled=false;
bool IsLastManStanding=false;

int top[3];

public Plugin:myinfo=
{
    name="Freak Fortress 2 : Deathmatch Mod",
    author="Nopied",
    description="....",
    version="0.1",
};

public void OnPluginStart()
{
    HookEvent("player_death", OnPlayerDeath, EventHookMode_Pre);
    HookEvent("arena_round_start", OnRoundStart);
    HookEvent("teamplay_round_win", OnRoundEnd, EventHookMode_Pre);
    //HookEvent("teamplay_win_panel", OnRoundEnd, EventHookMode_Pre);
    // TODO: pass 커맨드 구현.
}

public Action OnRoundStart(Handle event, const char[] name, bool dont)
{
    IsLastManStanding=false;
}

public Action OnRoundEnd(Handle event, const char[] name, bool dont)
{
  if(IsLastManStanding && enabled)
  {
    enabled=false;
    return Plugin_Handled;
  }
  return Plugin_Continue;
}

public Action OnPlayerDeath(Handle event, const char[] name, bool dont)
{
    if(IsBossTeam(GetClientOfUserId(GetEventInt(event, "userid"))) || GetEventInt(event, "death_flags") & TF_DEATHFLAG_DEADRINGER)
        return Plugin_Continue;
    // FIXME: 가끔
    // FIXME:당첨자가 마지막까지 살아있던 사람이었을 경우, 리스폰해도 그냥 사망처리됨.
    if(!IsLastManStanding && CheckAlivePlayers() <= 1) // 라스트 맨 스탠딩
    {
        IsLastManStanding=true;
        enabled=true;
        int bosses[MAXPLAYERS+1];
        int topDamage[3];
        int totalDamage;
        int bossCount;
        bool valid[3];

        for(int client=1; client<=MaxClients; client++)
        {
          if(!IsValidClient(client)) // for bossCount.
      			continue;
          else if(IsBoss(client)){
            bosses[bossCount++]=client;
            continue;
          }
          else if(IsBossTeam(client)) // FF2_GetClientDamage(client)<=0 ||
            continue;

      		if(FF2_GetClientDamage(client)>=FF2_GetClientDamage(top[0]))
      		{
      			top[2]=top[1];
      			top[1]=top[0];
      			top[0]=client;
      		}
      		else if(FF2_GetClientDamage(client)>=FF2_GetClientDamage(top[1]))
      		{
      			top[2]=top[1];
      			top[1]=client;
      		}
      		else if(FF2_GetClientDamage(client)>=FF2_GetClientDamage(top[2]))
      		{
      			top[2]=client;
      		}
        }

        char temp[3][35];

        for(int i; i<3; i++)
        {
            topDamage[i]=FF2_GetClientDamage(top[i]);
            valid[i]=IsValidClient(top[i]) && topDamage[i]>0;

            totalDamage+=valid[i] ? topDamage[i] : 0;
            //if(valid) Format(temp[0], sizeof(temp[]), "%N - %.1f", );
        }

        int random=GetRandomInt(0, totalDamage);
        int winner;

        for(int i; i<3; i++) // OH this stupid code..
        {
            int tempDamage;
            for (int x=i; x>=0; x--)
            {
                tempDamage+=FF2_GetClientDamage(top[x]);
            }
            if(random > tempDamage)
                continue;
            winner=top[i];
            break;
        }

        CPrintToChatAll("{olive}[FF2]{default} 확률: %N - %.2f%% | %N - %.2f%% | %N - %.2f%%\n %N님이 {red}강력한 무기{default}를 흭득하셨습니다!",
        top[0], float(FF2_GetClientDamage(top[0]))/float(totalDamage)*100.0,
        top[1], float(FF2_GetClientDamage(top[1]))/float(totalDamage)*100.0,
        top[2], float(FF2_GetClientDamage(top[2]))/float(totalDamage)*100.0,
        winner);

        for(int i; i<bossCount; i++)
        {
            int boss=FF2_GetBossIndex(bosses[i]);
            int newhealth=10000/bossCount;

            if(FF2_GetBossHealth(boss) < newhealth){
                FF2_SetBossMaxHealth(boss, newhealth);
                FF2_SetBossHealth(boss, newhealth);
            }
            FF2_SetBossCharge(boss, 0, 0.0);
        }


        // CreateTimer(0.02, BeLastMan, winner);
        // FF2_SetFF2flags(winner, FF2_GetFF2flags(winner)|FF2FLAG_CLASSTIMERDISABLED);

        /* TODO: Not Working. just spawn another person while winner is spawning.
        if(GetEventInt(event, "userid") == GetClientUserId(winner))
        {
          change=true;
          SetEventInt(event, "death_flags", GetEventInt(event, "death_flags")|TF_DEATHFLAG_DEADRINGER);
        }
        */

        if(GetEventInt(event, "userid") == GetClientUserId(winner))
        {
            int forWinner=FindAnotherPerson(winner);
            Handle data=CreateDataPack(); // In this? data = winner | forWinner | team |  IsAlive | abserverTarget(when he dead)
            WritePackCell(data, winner);
            WritePackCell(data, forWinner);
            WritePackCell(data, GetClientTeam(forWinner));
            TF2_ChangeClientTeam(forWinner, view_as<TFTeam>(FF2_GetBossTeam()) == TFTeam_Red ? TFTeam_Blue : TFTeam_Red);
            if(IsPlayerAlive(forWinner))
            {
                WritePackCell(data, 1);
            }
            else // Yeah. then it said. Not FakeClient and Not Alive.
            {
                TF2_RespawnPlayer(forWinner);
                WritePackCell(data, 0);
                WritePackCell(data, GetEntPropEnt(forWinner, Prop_Send, "m_hObserverTarget"));
            }
            ResetPack(data);
            CreateDataTimer(0.05, LastManCheck, data);
            return Plugin_Continue;

        }
        TF2_RespawnPlayer(winner);
        TF2_AddCondition(winner, TFCond_Ubercharged, 10.0);
        TF2_AddCondition(winner, TFCond_Stealthed, 10.0);
        GiveLastManWeapon(winner);
        return Plugin_Continue;
    }
    return Plugin_Continue;
}

public Action LastManCheck(Handle timer, Handle data)
{
    int winner=ReadPackCell(data);
    int client=ReadPackCell(data);
    TFTeam team=view_as<TFTeam>(ReadPackCell(data));
    bool alive=ReadPackCell(data);

    TF2_RespawnPlayer(winner);
    TF2_AddCondition(winner, TFCond_Ubercharged, 10.0);
    TF2_AddCondition(winner, TFCond_Stealthed, 10.0);
    GiveLastManWeapon(winner);

    if(alive)
    {
        TF2_ChangeClientTeam(client, team);
    }
    else
    {
        TF2_ChangeClientTeam(client, TFTeam_Spectator);
        TF2_ChangeClientTeam(client, team);

        SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", ReadPackCell(data));
    }
    return Plugin_Continue;
}


stock int FindAnotherPerson(int Gclient)
{
    int count;
    int validTarget[MAXPLAYERS+1];

    for(int client=1; client<=MaxClients; client++)
    {
        if(IsValidClient(client) && client != Gclient && !IsBoss(client))
        {
            validTarget[count++]=client;
        }
    }

    if(!count)
    {
        return CreateFakeClient("sorry. I can't find target.");
    }
    return validTarget[GetRandomInt(0, count-1)];
}

stock void GiveLastManWeapon(int client)
{
  bool changeMelee=true;

  TF2_RemoveAllWeapons(client);
  switch(TF2_GetPlayerClass(client))
  {
    case TFClass_Scout:
    {
      SpawnWeapon(client, "tf_weapon_scattergun", 200, 0, 2, "2027 ; 1 ; 2022 ; 1 ; 542 ; 1");
      SpawnWeapon(client, "tf_weapon_pistol", 209, 0, 2, _);
    }
    case TFClass_Sniper:
    {
      SpawnWeapon(client, "tf_weapon_sniperrifle", 201, 0, 2, "2027 ; 1 ; 2022 ; 1 ; 542 ; 1");
      SpawnWeapon(client, "tf_weapon_smg", 203, 0, 2, "2027 ; 1 ; 2022 ; 1 ; 542 ; 1");
    }
    case TFClass_Soldier:
    {
      SpawnWeapon(client, "tf_weapon_rocketlauncher", 205, 0, 2, "2027 ; 1 ; 2022 ; 1 ; 542 ; 1");
      // SpawnWeapon(client, "tf_weapon_shotgun", 199, 0, 2, _);
    }
    case TFClass_DemoMan:
    {
      SpawnWeapon(client, "tf_weapon_grenadelauncher", 206, 0, 2, "2027 ; 1 ; 2022 ; 1 ; 542 ; 1");
      SpawnWeapon(client, "tf_weapon_pipebomblauncher", 207, 0, 2, "2027 ; 1 ; 2022 ; 1 ; 542 ; 1");
      SpawnWeapon(client, "tf_weapon_sword", 132, 0, 2, "2027 ; 1 ; 2022 ; 1 ; 542 ; 1");
      changeMelee=false;
    }
    case TFClass_Medic:
    {
      SpawnWeapon(client, "tf_weapon_syringegun_medic", 36, 0, 2, "2027 ; 1 ; 2022 ; 1 ; 542 ; 1");
      SpawnWeapon(client, "tf_weapon_medigun", 211, 0, 2, "2027 ; 1 ; 2022 ; 1 ; 542 ; 1");
    }
    case TFClass_Heavy:
    {
      SpawnWeapon(client, "tf_weapon_minigun", 202, 0, 2, "2027 ; 1 ; 2022 ; 1 ; 542 ; 1");
      // SpawnWeapon(client, "tf_weapon_shotgun", 199, 0, 2, _);
    }
    case TFClass_Pyro:
    {
      SpawnWeapon(client, "tf_weapon_flamethrower", 208, 0, 2, "2027 ; 1 ; 2022 ; 1 ; 542 ; 1");
      SpawnWeapon(client, "tf_weapon_shotgun", 199, 0, 2, _);
    }
    case TFClass_Spy:
    {
      SpawnWeapon(client, "tf_weapon_revolver", 61, 0, 2, "2027 ; 1 ; 2022 ; 1 ; 542 ; 1");
      SpawnWeapon(client, "tf_weapon_knife", 194, 0, 2, "2027 ; 1 ; 2022 ; 1 ; 542 ; 1");
      SpawnWeapon(client, "tf_weapon_builder", 735, 0, 2, _);
      SpawnWeapon(client, "tf_weapon_invis", 30, 0, 2, _);
    }
    case TFClass_Engineer:
    {
      SpawnWeapon(client, "tf_weapon_sentry_revenge", 141, 0, 2, "2027 ; 1 ; 2022 ; 1 ; 542 ; 1");
      SpawnWeapon(client, "tf_weapon_wrench", 197, 0, 2, "2027 ; 1 ; 2022 ; 1 ; 542 ; 1");
      SpawnWeapon(client, "tf_weapon_pistol", 209, 0, 2, _);
      SpawnWeapon(client, "tf_weapon_pda_engineer_build", 25, 0, 2, _);
      int pda = SpawnWeapon(client, "tf_weapon_builder", 28, 0, 2, _);
      SetEntProp(pda, Prop_Send, "m_aBuildableObjectTypes", 1, _, 0);
      SetEntProp(pda, Prop_Send, "m_aBuildableObjectTypes", 1, _, 1);
      SetEntProp(pda, Prop_Send, "m_aBuildableObjectTypes", 1, _, 2);
      SetEntProp(pda, Prop_Send, "m_aBuildableObjectTypes", 0, _, 3);
      SpawnWeapon(client, "tf_weapon_pda_engineer_destroy", 26, 0, 2, _);
      changeMelee=false;
    }
  }
  if(changeMelee)
    SpawnWeapon(client, "tf_weapon_bottle", 1071, 0, 1, "2027 ; 1 ; 2022 ; 1 ; 542 ; 1");

}

stock int SpawnWeapon(int client, char[] name, int index, int level, int quality, char[] attribute="")
{
	Handle weapon=TF2Items_CreateItem(OVERRIDE_ALL|FORCE_GENERATION);
	TF2Items_SetClassname(weapon, name);
	TF2Items_SetItemIndex(weapon, index);
	TF2Items_SetLevel(weapon, level);
	TF2Items_SetQuality(weapon, quality);
	char attributes[32][32];
	int count = ExplodeString(attribute, ";", attributes, 32, 32);
	if(count%2!=0)
	{
		count--;
	}

	if(count>0)
	{
		TF2Items_SetNumAttributes(weapon, count/2);
		int i2=0;
		for(int i=0; i<count; i+=2)
		{
			int attrib=StringToInt(attributes[i]);
			if(attrib==0)
			{
				LogError("Bad weapon attribute passed: %s ; %s", attributes[i], attributes[i+1]);
				return -1;
			}
			TF2Items_SetAttribute(weapon, i2, attrib, StringToFloat(attributes[i+1]));
			i2++;
		}
	}
	else
	{
		TF2Items_SetNumAttributes(weapon, 0);
	}

	if(weapon==INVALID_HANDLE)
	{
		return -1;
	}
	int entity=TF2Items_GiveNamedItem(client, weapon);
	CloseHandle(weapon);
	EquipPlayerWeapon(client, entity);
	return entity;
}

stock bool IsValidClient(int client)
{
    return (0<client && client<=MaxClients && IsClientInGame(client));
}

stock int CheckAlivePlayers() // Without bosses. LOL
{
    int alive=0;

    for(int i=1; i<=MaxClients; i++)
    {
        if(IsValidClient(i) && IsPlayerAlive(i) && FF2_GetBossTeam() != GetClientTeam(i))
            alive++;
    }

    return alive;
}

stock bool IsBoss(int client)
{
    return FF2_GetBossIndex(client) != -1;
}

stock bool IsBossTeam(int client)
{
    return FF2_GetBossTeam() == GetClientTeam(client);
}
