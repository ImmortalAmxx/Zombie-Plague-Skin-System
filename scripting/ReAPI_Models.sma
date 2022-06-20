/**
    История изминений:
        - 0.1 beta (20.05.2022) - Первый релиз.

    Благодарности: b0t.
*/

#include <AmxModX>
#include <ReApi>
#include <ReApi_V>
#include <ZombiePlague>

native zp_override_user_model(iIndex, szModelName[], iMIndex);

enum _:ARRAY_DATA {
    DATA[32],               //Key: f -- flag | s -- Steam | i -- Ip;
    INDEX[32],              //Check Index;
    NAME_MODEL[32],         //Model way;
    BODY[32],                   //BodyGroup model.
    SKIN[32],                   //Skin model.
    IKEY                    //Model index;
};

new const szPlInf[][] = {
    // Информация по поводу плагина.
    "[ZP 4.3] System: Models",
    "0.1 beta",
    "ImmortalAmxx",

    //Название ини файла.
    "re_zpmodels.ini"
};

new Array:g_aModelData;

public plugin_precache() {
    g_aModelData = ArrayCreate(ARRAY_DATA);

    UTIL_ReadFile();
}

public plugin_init() {
    register_plugin(
        .plugin_name = szPlInf[0],
        .version = szPlInf[1],
        .author = szPlInf[2]
    );

    RegisterHookChain(RG_CBasePlayer_Spawn, "CBasePlayer_Spawn_Post", true);
}

public CBasePlayer_Spawn_Post(pPlayer) {
    if(zp_get_user_zombie(pPlayer) || zp_get_user_survivor(pPlayer) || zp_get_user_nemesis(pPlayer) || !is_user_alive(pPlayer))
        return;

    RequestFrame("SetUserModel", pPlayer);       
}

public zp_user_humanized_post(pPlayer, pSurvivor) {
    if(pSurvivor || !is_user_connected(pPlayer) || !is_user_alive(pPlayer))
        return;

    RequestFrame("SetUserModel", pPlayer);
}

public SetUserModel(pPlayer) {
    new aData[ARRAY_DATA], iItem = -1;

    for(new iCase; iCase < ArraySize(g_aModelData); iCase++) {
        ArrayGetArray(g_aModelData, iCase, aData);

        static szKey[64];
        switch(aData[DATA]) {
            case 's': {
                get_user_authid(pPlayer, szKey, charsmax(szKey));

                if(equal(szKey, aData[INDEX])) {
                    iItem = iCase;
                    break;
                }                
            }
            case 'f': {
                if(get_user_flags(pPlayer) & read_flags(aData[INDEX])) {
                    iItem = iCase;
                    break;
                }
            }
            case 'i': {
                get_user_ip(pPlayer, szKey, charsmax(szKey), 1);

                if(equal(szKey, aData[INDEX])) {
                    iItem = iCase;
                    break;              
                }
            }
            case 'n': {
                get_user_name(pPlayer, szKey, charsmax(szKey));

                if(equal(szKey, aData[INDEX])) {
                    iItem = iCase;
                    break;              
                }
            }
        }
    }

    if(iItem != -1) {
        ArrayGetArray(g_aModelData, iItem, aData);

        new iModelIndex = aData[IKEY];

        zp_override_user_model(pPlayer, aData[NAME_MODEL], iModelIndex);
        set_member(pPlayer, m_modelIndexPlayer, iModelIndex);

        if(aData[BODY] != EOS)
            set_entvar(pPlayer, var_body, str_to_num(aData[BODY]));

        if(aData[SKIN] != EOS)
            set_entvar(pPlayer, var_skin, str_to_num(aData[SKIN]));
    }
}

stock UTIL_ReadFile() {
    new szData[256], f, aData[ARRAY_DATA];
    formatex(szData, charsmax(szData), "addons/amxmodx/configs/%s", szPlInf[3]);

    f = fopen(szData, "r");
    
    while(!feof(f)) {
        fgets(f, szData, charsmax(szData));
        trim(szData);

        if(szData[0] == EOS || szData[0] == ';' || szData[0] == '/' && szData[1] == '/')
            continue;

        if(szData[0] == '"') {
            parse(szData,
                aData[DATA], charsmax(aData),
                aData[INDEX], charsmax(aData),
                aData[NAME_MODEL], charsmax(aData),
                aData[BODY], charsmax(aData),
                aData[SKIN], charsmax(aData)
            );

            if(file_exists(fmt("models/player/%s/%s.mdl", aData[NAME_MODEL], aData[NAME_MODEL])))
                aData[IKEY] = precache_model(fmt("models/player/%s/%s.mdl", aData[NAME_MODEL], aData[NAME_MODEL]));
            else {
                server_print("%s - Bad load model: %s", szPlInf[0], aData[NAME_MODEL]);
                server_print("%s - Plugin paused.", szPlInf[0]);
                
                pause("d");
                break;
            }

            ArrayPushArray(g_aModelData, aData);
        }
        else
            continue;
    }
    fclose(f);
}