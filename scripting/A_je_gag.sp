#include <sourcemod>
#include <morecolors>
#include <clientprefs>

Handle g_hGagCookie;

public Plugin:myinfo = {
	name = "A_je_gag",
	description = "Yeah.",
	author = "Nopied◎",
	version = "18",
};

public void OnPluginStart()
{
  g_hGagCookie=RegClientCookie("A_je_gag.cookie", "LOL", CookieAccess_Protected);

	AddCommandListener(Listener_Say, "say");
	AddCommandListener(Listener_Say, "say_team");

  RegConsoleCmd("ajegag", Command_Ajegag);

  CreateTimer(90.0, Timer_Gag, _, TIMER_REPEAT);
}

public Action Timer_Gag(Handle timer)
{
  char cookieClient[MAXPLAYERS+1][100];
  char CookieV[100];
  int clientQueue[MAXPLAYERS+1]; // 이것도 0은 취급 안함.
  int count=0; // for문의 client는 1부터 시작.

  for(int client=1; client<=MaxClients; client++) // 0은 World.
  {
    if(IsValidClient(client))
    {
      GetClientCookie(client, g_hGagCookie, CookieV, sizeof(CookieV));
      if(CookieV[0] != '\0')
      {
        Format(cookieClient[count], 100, "%s", CookieV);
        clientQueue[count]=client;
				count++;
      }
    }
  }
  int random=GetRandomInt(0, count-1);
	if(count)
  CPrintToChatAll("{green}[개그]{default} %s{default} - {green}%N",
	cookieClient[random],
	clientQueue[random]);
  return Plugin_Continue;
}

public Action:Listener_Say(int client, const char[] command, int argc)
{
	if(!IsValidClient(client))	return Plugin_Continue;

	char chat[150];
	char gag[2][100];
	int start=0;
	GetCmdArgString(strChat, sizeof(strChat));

	if(chat[start]=='"') start++;
	if(chat[start]=='!' || chat[start]=='/') start++;

	ExplodeString(chat[start], " ", gag, 2, 100);
	if(StrEqual("개그", gag[0], true))
	{
		CheckGag(client, gag[1]);
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action Command_Ajegag(int client, int args)
{
  if(!IsValidClient(client)) return Plugin_Continue;

  char gag[150];
  GetCmdArgString(gag, sizeof(gag));

	CheckGag(client, gag);
  return Plugin_Continue;
}

void CheckGag(int client, const char[] gag)
{
	if(gag[0] != '\0')
  {
    SetClientCookie(client, g_hGagCookie, gag);
    CPrintToChat(client, "{green}[개그]{default} ''%s''로 설정하셨습니다.", gag);
    return;
  }
  else
  {
		char CookieV[150];
		GetClientCookie(client, g_hGagCookie, CookieV, sizeof(CookieV));

		if(CookieV[0] == '\0')
	  {
			CPrintToChat(client, "{green}[개그]{default} 등록할 개그를 적어주세요!");
		}
    else
		{
			SetClientCookie(client, g_hGagCookie, "");
			CPrintToChat(client, "{green}[개그]{default} 개그를 초기화했습니다.");
		}
  }
}

stock bool IsValidClient(client)
{
	return (0 < client && client < MaxClients && IsClientInGame(client));
}
