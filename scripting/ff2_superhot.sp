#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2_stocks>
#include <morecolors>
#include <freak_fortress_2>
#include <freak_fortress_2_subplugin>

public Plugin:myinfo=
{
    name="Freak Fortress 2 : SUPERHOT's Ability",
    author="Nopied",
    description="FF2",
    version="1.0",
};

float g_flDoNotChange;

public void OnPluginStart2()
{
    HookEvent("teamplay_round_start", OnRoundStart);
    HookEvent("teamplay_round_win", OnRoundEnd, EventHookMode_Pre);
}

public Action OnRoundStart(Handle event, const char[] name, bool dont)
{
    g_flDoNotChange = 0.0;
}

public Action OnRoundEnd(Handle event, const char[] name, bool dont)
{
    ConVar timeScale = FindConVar("host_timescale");
    timeScale.FloatValue = 1.0;

    UpdateClientCheatValue(0);

    int mainboss = FF2_GetBossIndex(0);
    char tempPath[PLATFORM_MAX_PATH];
    FF2_GetAbilityArgumentString(mainboss, this_plugin_name, "ff2_superhot", 4, tempPath, PLATFORM_MAX_PATH);

	for(int target=1; target<=MaxClients; target++)
	{
		if(IsValidClient(target))
			StopSound(target, SNDCHAN_AUTO, tempPath);
	}


}

public void OnGameFrame()
{
    if(FF2_GetRoundState() != 1) return;

    int mainboss;
    mainboss = FF2_GetBossIndex(0);

    if(FF2_HasAbility(mainboss, this_plugin_name, "ff2_superhot"))
    {
        if(g_flDoNotChange > GetGameTime())
        {
            return;
        }

        UpdateClientCheatValue(1);

        int client = GetClientOfUserId(FF2_GetBossUserId(mainboss));
        bool timeFaster = false;
        float tempVelocity[3];
        GetEntPropVector(client, Prop_Data, "m_vecVelocity", tempVelocity);

        if(GetVectorLength(tempVelocity) > 1.0)
        {
            timeFaster = true;
        }

        Handle timeScale = FindConVar("host_timescale");
        float tempTimeScale = GetConVarFloat(timeScale);
        tempTimeScale += timeFaster ? GetTickInterval() * 4.0 : GetTickInterval() * -4.0;

        if(FF2_GetAbilityDuration(mainboss, 0) > 0.0)
        {
            if(tempTimeScale < FF2_GetAbilityArgumentFloat(mainboss, this_plugin_name, "ff2_superhot", 3, 0.1))
            {
                tempTimeScale = FF2_GetAbilityArgumentFloat(mainboss, this_plugin_name, "ff2_superhot", 3, 0.1);
            }
        }
        else
        {
            if(tempTimeScale > FF2_GetAbilityArgumentFloat(mainboss, this_plugin_name, "ff2_superhot", 1, 1.8))
            {
                tempTimeScale = FF2_GetAbilityArgumentFloat(mainboss, this_plugin_name, "ff2_superhot", 1, 1.8);
            }
            else if(tempTimeScale < FF2_GetAbilityArgumentFloat(mainboss, this_plugin_name, "ff2_superhot", 2, 0.1))
            {
                tempTimeScale = FF2_GetAbilityArgumentFloat(mainboss, this_plugin_name, "ff2_superhot", 2, 0.1);
            }
        }

        // if(tempTimeScale % 0.1 > 0.0) // % 연산자님?

        int tempTempTimeScale = RoundFloat(tempTimeScale * 10.0);

        if(GetConVarFloat(timeScale) != tempTempTimeScale)
        {
            SetConVarFloat(timeScale, tempTempTimeScale / 10.0);
            g_flDoNotChange = (GetGameTime() + 1.5) * (tempTempTimeScale / 10.0);
        }

        PrintCenterTextAll("%.1f", tempTimeScale);
    }
}

public Action FF2_OnAbility2(int boss, const char[] plugin_name, const char[] ability_name, int status)
{
    // int client = GetClientOfUserId(FF2_GetBossUserId(boss));

    if(StrEqual(ability_name, "ff2_superhot"))
    {
        char tempPath[PLATFORM_MAX_PATH];
        FF2_GetAbilityArgumentString(boss, this_plugin_name, "ff2_superhot", 4, tempPath, PLATFORM_MAX_PATH);

        EmitSoundToAll(tempPath, _, _, SNDLEVEL_ROCKET);
    }
}

public Action FF2_OnAbilityTimeEnd(int boss, int slot)
{
    if(FF2_HasAbility(boss, this_plugin_name, "ff2_superhot"))
    {
      char tempPath[PLATFORM_MAX_PATH];
      FF2_GetAbilityArgumentString(boss, this_plugin_name, "ff2_superhot", 4, tempPath, PLATFORM_MAX_PATH);

      for(int target=1; target<=MaxClients; target++)
      {
          if(IsValidClient(target))
          StopSound(target, SNDCHAN_AUTO, tempPath);
      }
    }
}

stock void UpdateClientCheatValue(value)
{
	for(int client=1; client<=MaxClients; client++)
	{
		if(IsClientInGame(client) && !IsFakeClient(client))
		{
			SendConVarValue(client, FindConVar("sv_cheats"), value ? "1" : "0");
		}
	}
}

stock bool IsValidClient(int client)
{
    return (0<client && client<=MaxClients && IsClientInGame(client));
}
