#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2_stocks>
#include <morecolors>
#include <freak_fortress_2>
#include <freak_fortress_2_subplugin>

Handle RageTimer[MAXPLAYERS+1];
Handle RageData;

bool g_bUseAbility[MAXPLAYERS+1]={false, ...};
int g_iFogIndex=-1;

public Plugin:myinfo=
{
    name="Freak Fortress 2 : Freddy Krueger's Ability",
    author="Nopied",
    description="FF2",
    version="1.0",
};

public void OnPluginStart2()
{
    AddNormalSoundHook(SoundHook);
    AddAmbientSoundHook(SoundAmbientHook);
}

public Action FF2_OnAbility2(int boss, const char[] plugin_name, const char[] ability_name, int status)
{
    if(!strcmp(ability_name, "ff2_freddykrueger"))
    {
        Ability_FreddyKrueger(boss, ability_name);
    }
}

/*
Arg 1: 안개 시작
Arg 2: 안개 끝
Arg 3: 안개 색
*/

void Ability_FreddyKrueger(int boss, const char[] ability_name)
{
    new client=GetClientOfUserId(FF2_GetBossUserId(boss));

    g_bUseAbility[client]=true;
    SetEntPropFloat(client, Prop_Send, "m_fadeMinDist", 50.0);
    SetEntPropFloat(client, Prop_Send, "m_fadeMaxDist", 500.0);
    CreateTimer(15.0, ActiveNight, client);
}

public Action ActiveNight(Handle time, int client)
{
    g_bUseAbility[client]=false;

    if(IsValidClient(client) && IsPlayerAlive(client))
    {
        SetEntPropFloat(client, Prop_Send, "m_fadeMinDist", 0.0);
        SetEntPropFloat(client, Prop_Send, "m_fadeMaxDist", 0.0);
        // m_flFadeScale
    }
}

public Action SoundHook(int clients[64], int &numClients, char sample[PLATFORM_MAX_PATH], int &entity, int &channel, float &volume, int &level, int &pitch, int &flags)
{
    if(IsValidClient(entity) && g_bUseAbility[entity])
    {
        volume=0.0;
        StopSound(entity, channel, sample);
        return Plugin_Changed;
    }
    return Plugin_Continue;
}

public Action SoundAmbientHook(char sample[PLATFORM_MAX_PATH], int &entity, float &volume, int &level, int &pitch, float pos[3], int &flags, float &delay)
{
    if(IsValidClient(entity) && g_bUseAbility[entity])
    {
        volume=0.0;
        StopSound(entity, 0, sample);
        return Plugin_Changed;
    }
    return Plugin_Continue;
}

stock void SpawnFog(float fogStart, float fogEnd, const char color[25])
{ // TODO: 안개가 이미 있다고? 그럼 그 안개를 이용해!
    g_iFogIndex=CreateEntityByName("env_fog_controller");
    DispatchSpawn(g_iFogIndex);
    if(IsValidEntity(g_iFogIndex))
    {
        SetVariantFloat(fogStart);
        AcceptEntityInput(g_iFogIndex, "SetStartDist");
        SetVariantFloat(fogEnd);
        AcceptEntityInput(g_iFogIndex, "SetEndDist");
        SetVariantString(color);
        AcceptEntityInput(g_iFogIndex, "SetColor");
        SetVariantString("!activator");
        AcceptEntityInput(g_iFogIndex, "SetFogController");
        AcceptEntityInput(g_iFogIndex, "TurnOn");

        if(!IsValidEntity(g_iFogIndex))
        {
            g_iFogIndex=-1;
            PrintToChatAll("이 안개는 정상이 아님!");
        }
    }
    else g_iFogIndex=-1;
}

stock void KillFog()
{
    if(IsValidEntity(g_iFogIndex))
    {
        AcceptEntityInput(g_iFogIndex, "Kill");
    }
}

stock bool IsValidClient(int client)
{
    return (0<client && client <= MaxClients && IsClientInGame(client));
}
