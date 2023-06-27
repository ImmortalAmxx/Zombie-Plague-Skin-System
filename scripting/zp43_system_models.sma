/**
    История изминений:
        - 1.1 beta (20.05.2022) - Первый релиз.
        - 1.2 (17.12.2022) - Правка бага с проверками (Спасибо cookie.).
        - 1.3 (11.03.2023) - Изменения в коде, добавленна возможность выставлять время действия.

    Благодарности: b0t.
*/

#include <amxmodx>
#include <reapi>
#include <zombieplague>

native zp_override_user_model(iIndex, szModelName[], iMIndex);

enum any: DataStruct
{
    DATA[32],
    INDEX[32],
    NAME_MODEL[32],
    BODY[6],
    SKIN[6],
    TIME[24],
    IKEY
};

new const PATHFILE[] = "re_zpmodels.ini";

new Array:gl_aModelData;

public plugin_precache() 
{
    gl_aModelData = ArrayCreate(DataStruct);

    ReadFile();
}

public plugin_init()
{
    register_plugin("[ZP 4.3] System: Models", "1.3", "ImmortalAmxx");
    
    RegisterHookChain(RG_CBasePlayer_Spawn, "CBasePlayer_Spawn_Post", true);
}

public CBasePlayer_Spawn_Post(UserId)
{
    if(!is_user_connected(UserId))
    {
        return;
    }

    set_task(0.5, "SetUserModel", UserId);       
}

public zp_user_humanized_post(UserId, pSurvivor) {
    if(pSurvivor || !is_user_connected(UserId))
    {
        return;
    }
    
    set_task(0.5, "SetUserModel", UserId);
}

public SetUserModel(UserId) {
    new aData[DataStruct], iItem = -1;

    for(new iCase; iCase < ArraySize(gl_aModelData); iCase++)
    {
        ArrayGetArray(gl_aModelData, iCase, aData);

        static szKey[64];
        switch(aData[DATA])
        {
            case 's':
            {
                get_user_authid(UserId, szKey, charsmax(szKey));

                if(equal(szKey, aData[INDEX])) {
                    iItem = iCase;
                    break;
                }                
            }
            case 'f':
            {
                if(get_user_flags(UserId) & read_flags(aData[INDEX])) {
                    iItem = iCase;
                    break;
                }
            }
            case 'i':
            {
                get_user_ip(UserId, szKey, charsmax(szKey), 1);

                if(equal(szKey, aData[INDEX])) {
                    iItem = iCase;
                    break;              
                }
            }
            case 'n':
            {
                get_user_name(UserId, szKey, charsmax(szKey));

                if(equal(szKey, aData[INDEX])) {
                    iItem = iCase;
                    break;              
                }
            }
        }
    }

    if(iItem != -1)
    {
        if(!zp_get_user_survivor(UserId) && !zp_get_user_nemesis(UserId) && !zp_get_user_zombie(UserId))
        {
            ArrayGetArray(gl_aModelData, iItem, aData);

            new iModelIndex = aData[IKEY];

            zp_override_user_model(UserId, aData[NAME_MODEL], iModelIndex);
            set_member(UserId, m_modelIndexPlayer, iModelIndex);

            if(aData[BODY][0])
            {
                set_entvar(UserId, var_body, str_to_num(aData[BODY]));
            }
            
            if(aData[SKIN][0])
            {
                set_entvar(UserId, var_skin, str_to_num(aData[SKIN]));
            }
        }
    }
}

ReadFile()
{
    new szData[256], f, aData[DataStruct], SysTime;
    formatex(szData, charsmax(szData), "addons/amxmodx/configs/%s", PATHFILE);

    SysTime = get_systime();

    f = fopen(szData, "r");
    
    while(!feof(f)) 
    {
        fgets(f, szData, charsmax(szData));
        trim(szData);

        if(szData[0] == EOS || szData[0] == ';' || szData[0] == '/' && szData[1] == '/')
        {
            continue;
        }
        
        if(szData[0] == '"')
        {
            parse(szData,
                aData[DATA], charsmax(aData),
                aData[INDEX], charsmax(aData),
                aData[NAME_MODEL], charsmax(aData),
                aData[BODY], charsmax(aData),
                aData[SKIN], charsmax(aData),
                aData[TIME], charsmax(aData)
            );

            if(file_exists(fmt("models/player/%s/%s.mdl", aData[NAME_MODEL], aData[NAME_MODEL])))
            {
                aData[IKEY] = precache_model(fmt("models/player/%s/%s.mdl", aData[NAME_MODEL], aData[NAME_MODEL]));
            }
            else
            {
                server_print("[ZP SKINS] - Bad load model: %s", aData[NAME_MODEL]);
                server_print("[ZP SKINS] - Plugin paused.");
                
                pause("d");
                break;
            }
            
            if(aData[TIME][0] && SysTime >= parse_time(aData[TIME], "%d.%m.%Y %H:%M"))
            {
                continue;
            }

            ArrayPushArray(gl_aModelData, aData);
        }
        else
        {
            continue;
        }
    }
    fclose(f);
}
